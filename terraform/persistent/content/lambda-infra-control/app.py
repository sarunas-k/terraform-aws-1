"""Starts the apply and destroy GitHub workflows.

Callers: web page buttons via the function URL and EventBridge Scheduler.
"""
import base64
import hmac
import json
import logging
import os
import time
from datetime import datetime, timezone

import control
import github_api

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

ROUTES = {"/wake": "wake", "/destroy": "destroy"}
WRONG_PASSCODE_DELAY_SECONDS = 2
MAX_BODY_CHARS = 2048
SECRET_CACHE_SECONDS = 300

_secret_cache = {"value": None, "loaded_at": 0.0}


def handler(event, context):
    # Only function URL requests have requestContext
    if "requestContext" in event:
        return handle_http(event)
    return handle_schedule(event)


# ---------------------------
# Function URL (buttons)
# ---------------------------
def handle_http(event):
    http = event["requestContext"]["http"]
    if http["method"] != "POST":
        return respond(405, "method_not_allowed", "Use POST.")
    action = ROUTES.get(event.get("rawPath", ""))
    if action is None:
        return respond(404, "not_found", "Unknown path.")

    try:
        body = parse_body(event)
    except ValueError:
        return respond(400, "bad_request", "The request body must be a small JSON object.")

    try:
        secret = load_secret()
    except Exception:  # noqa: BLE001
        logger.exception("Could not read the secret")
        return respond(500, "not_configured", "The service is not configured yet.")

    if not passcode_ok(body.get("passcode"), secret.get("passcode")):
        logger.warning("Wrong passcode for %s from %s", action, http.get("sourceIp"))
        time.sleep(WRONG_PASSCODE_DELAY_SECONDS)
        return respond(401, "wrong_passcode", "Wrong passcode.")

    try:
        decision, run_url = run_action(action, secret["github_token"])
    except github_api.GitHubError as error:
        logger.error("GitHub call failed: %s", error)
        return respond(502, "github_error", "Could not reach GitHub. Try again in a minute.")

    logger.info("%s -> %s (%s)", action, decision.key, decision.status)
    return respond(decision.status, decision.key, decision.message,
                   retry_after=decision.retry_after, run_url=run_url)


def parse_body(event):
    raw = event.get("body") or ""
    if event.get("isBase64Encoded"):
        raw = base64.b64decode(raw).decode()
    if len(raw) > MAX_BODY_CHARS:
        raise ValueError("body too large")
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError("body must be a JSON object")
    return data


def passcode_ok(given, expected):
    if not isinstance(given, str) or not expected:
        return False
    return hmac.compare_digest(given.encode(), expected.encode())


def respond(status, key, message, retry_after=0, run_url=None):
    # No CORS headers: the function URL adds them, duplicates are rejected by browsers
    headers = {"Content-Type": "application/json", "Cache-Control": "no-store"}
    body = {"status": key, "message": message}
    if retry_after:
        headers["Retry-After"] = str(retry_after)
        body["retryAfterSeconds"] = retry_after
    if run_url:
        body["runUrl"] = run_url
    return {"statusCode": status, "headers": headers, "body": json.dumps(body)}


# ---------------------------
# EventBridge Scheduler (daily shutdown)
# ---------------------------
def handle_schedule(event):
    if event.get("source") != "scheduler" or event.get("action") != "destroy":
        logger.error("Ignoring unknown event: %s", json.dumps(event)[:200])
        return {"status": "ignored"}
    # Not caught, so a failed invocation is retried
    secret = load_secret()
    decision, run_url = run_action("destroy", secret["github_token"], scheduled=True)
    logger.info("Scheduled destroy -> %s: %s %s", decision.key, decision.message, run_url or "")
    return {"status": decision.key}


# ---------------------------
# Shared
# ---------------------------
def run_action(action, token, scheduled=False):
    """Look at the recent runs, decide, and start the workflow if allowed."""
    repo = os.environ["GITHUB_REPO"]
    apply_file = os.environ["APPLY_WORKFLOW"]
    destroy_file = os.environ["DESTROY_WORKFLOW"]
    cooldown = int(os.environ["COOLDOWN_SECONDS"])

    apply_runs = github_api.list_runs(repo, apply_file, token)
    destroy_runs = github_api.list_runs(repo, destroy_file, token)
    now = datetime.now(timezone.utc)

    if action == "wake":
        decision = control.decide_wake(apply_runs, destroy_runs, now, cooldown)
    elif scheduled:
        decision = control.decide_scheduled_destroy(destroy_runs)
    else:
        decision = control.decide_destroy(destroy_runs, now, cooldown)

    run_url = None
    if decision.dispatch and action == "wake":
        run_url = github_api.dispatch(repo, apply_file, token)
    elif decision.dispatch:
        run_url = github_api.dispatch(repo, destroy_file, token, inputs={"confirm": "destroy"})
    return decision, run_url


def load_secret():
    """Secret JSON with github_token and passcode, cached while the container is warm."""
    now = time.monotonic()
    if _secret_cache["value"] is None or now - _secret_cache["loaded_at"] > SECRET_CACHE_SECONDS:
        import boto3

        client = boto3.client("secretsmanager")
        response = client.get_secret_value(SecretId=os.environ["SECRET_ID"])
        _secret_cache["value"] = json.loads(response["SecretString"])
        _secret_cache["loaded_at"] = now
    return _secret_cache["value"]
