"""Handler tests with GitHub and Secrets Manager faked. Run: python3 -m unittest discover -s tests"""
import base64
import json
import os
import sys
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import app  # noqa: E402
import github_api  # noqa: E402

SECRET = {"github_token": "ghp_fake", "passcode": "open-sesame"}
ENV = {
    "GITHUB_REPO": "owner/repo",
    "APPLY_WORKFLOW": "apply.yml",
    "DESTROY_WORKFLOW": "destroy.yml",
    "COOLDOWN_SECONDS": "600",
    "SECRET_ID": "infra-control",
}


def old_run(minutes_ago=300, conclusion="success"):
    created = datetime.now(timezone.utc) - timedelta(minutes=minutes_ago)
    return {"created_at": created.isoformat(), "status": "completed", "conclusion": conclusion}


def http_event(path="/wake", method="POST", body=None, raw_body=None):
    if raw_body is None:
        raw_body = json.dumps(body if body is not None else {"passcode": "open-sesame"})
    return {
        "rawPath": path,
        "body": raw_body,
        "isBase64Encoded": False,
        "requestContext": {"http": {"method": method, "sourceIp": "203.0.113.9"}},
    }


class HandlerTests(unittest.TestCase):
    def setUp(self):
        patches = [
            mock.patch.dict(os.environ, ENV),
            mock.patch.object(app, "load_secret", return_value=SECRET),
            mock.patch.object(app.time, "sleep"),
            mock.patch.object(github_api, "list_runs", return_value=[]),
            mock.patch.object(github_api, "dispatch", return_value="https://github.com/o/r/actions/runs/1"),
        ]
        for patch in patches:
            patch.start()
            self.addCleanup(patch.stop)
        self.list_runs = github_api.list_runs
        self.dispatch = github_api.dispatch

    def call(self, event):
        response = app.handler(event, None)
        return response, json.loads(response["body"]) if "body" in response else None

    def test_wake_starts_apply(self):
        response, body = self.call(http_event("/wake"))
        self.assertEqual(response["statusCode"], 202)
        self.assertEqual(body["status"], "started")
        self.assertEqual(body["runUrl"], "https://github.com/o/r/actions/runs/1")
        self.dispatch.assert_called_once_with("owner/repo", "apply.yml", "ghp_fake")

    def test_destroy_sends_confirmation_input(self):
        response, _ = self.call(http_event("/destroy"))
        self.assertEqual(response["statusCode"], 202)
        self.dispatch.assert_called_once_with(
            "owner/repo", "destroy.yml", "ghp_fake", inputs={"confirm": "destroy"})

    def test_wrong_passcode(self):
        response, body = self.call(http_event(body={"passcode": "nope"}))
        self.assertEqual(response["statusCode"], 401)
        self.assertEqual(body["status"], "wrong_passcode")
        self.dispatch.assert_not_called()
        self.list_runs.assert_not_called()
        app.time.sleep.assert_called_once_with(app.WRONG_PASSCODE_DELAY_SECONDS)

    def test_missing_or_wrong_type_passcode(self):
        for payload in ({}, {"passcode": 123}, {"passcode": None}, {"passcode": ["open-sesame"]}):
            response, _ = self.call(http_event(body=payload))
            self.assertEqual(response["statusCode"], 401, payload)
        self.dispatch.assert_not_called()

    def test_get_is_rejected(self):
        response, _ = self.call(http_event(method="GET"))
        self.assertEqual(response["statusCode"], 405)

    def test_unknown_path(self):
        response, _ = self.call(http_event("/admin"))
        self.assertEqual(response["statusCode"], 404)
        self.dispatch.assert_not_called()

    def test_bad_json(self):
        response, _ = self.call(http_event(raw_body="{not json"))
        self.assertEqual(response["statusCode"], 400)

    def test_body_must_be_an_object(self):
        response, _ = self.call(http_event(raw_body='["open-sesame"]'))
        self.assertEqual(response["statusCode"], 400)

    def test_oversized_body(self):
        response, _ = self.call(http_event(raw_body=json.dumps({"passcode": "x" * 5000})))
        self.assertEqual(response["statusCode"], 400)

    def test_base64_body(self):
        raw = base64.b64encode(json.dumps({"passcode": "open-sesame"}).encode()).decode()
        event = http_event(raw_body=raw)
        event["isBase64Encoded"] = True
        response, _ = self.call(event)
        self.assertEqual(response["statusCode"], 202)

    def test_github_down_gives_502_without_details(self):
        self.list_runs.side_effect = github_api.GitHubError(500, "secret internal detail")
        response, body = self.call(http_event())
        self.assertEqual(response["statusCode"], 502)
        self.assertNotIn("secret internal detail", json.dumps(body))

    def test_secret_unreadable_gives_500(self):
        with mock.patch.object(app, "load_secret", side_effect=RuntimeError("boom")):
            response, body = self.call(http_event())
        self.assertEqual(response["statusCode"], 500)
        self.assertNotIn("boom", json.dumps(body))

    def test_cooldown_sets_retry_after_header(self):
        self.list_runs.return_value = [old_run(minutes_ago=3, conclusion="failure")]
        response, body = self.call(http_event("/wake"))
        self.assertEqual(response["statusCode"], 429)
        self.assertEqual(response["headers"]["Retry-After"], str(body["retryAfterSeconds"]))
        self.dispatch.assert_not_called()

    def test_no_cors_headers_set_by_function(self):
        response, _ = self.call(http_event())
        self.assertFalse([h for h in response["headers"] if h.lower().startswith("access-control")])

    def test_scheduler_destroys(self):
        result = app.handler({"source": "scheduler", "action": "destroy"}, None)
        self.assertEqual(result, {"status": "started"})
        self.dispatch.assert_called_once_with(
            "owner/repo", "destroy.yml", "ghp_fake", inputs={"confirm": "destroy"})

    def test_scheduler_skips_while_destroy_runs(self):
        running = dict(old_run(1), status="in_progress", conclusion=None)
        self.list_runs.side_effect = lambda repo, workflow, token, branch="main": (
            [running] if workflow == "destroy.yml" else [])
        result = app.handler({"source": "scheduler", "action": "destroy"}, None)
        self.assertEqual(result, {"status": "destroy_running"})
        self.dispatch.assert_not_called()

    def test_scheduler_ignores_other_events(self):
        for event in ({}, {"source": "scheduler"}, {"source": "scheduler", "action": "wake"},
                      {"source": "other", "action": "destroy"}):
            self.assertEqual(app.handler(event, None), {"status": "ignored"}, event)
        self.dispatch.assert_not_called()

    def test_passcode_check_is_constant_time_helper(self):
        self.assertTrue(app.passcode_ok("a", "a"))
        self.assertFalse(app.passcode_ok("a", "b"))
        self.assertFalse(app.passcode_ok("a", ""))
        self.assertFalse(app.passcode_ok("é", "e"))


if __name__ == "__main__":
    unittest.main()
