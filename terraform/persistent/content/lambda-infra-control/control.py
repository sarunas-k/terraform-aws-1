"""Rules for starting deploy and shutdown runs.
"""
from dataclasses import dataclass
from datetime import datetime

ACTIVE_STATUSES = {"queued", "in_progress", "waiting", "requested", "pending"}


@dataclass
class Decision:
    dispatch: bool
    status: int
    key: str
    message: str  # shown on the page
    retry_after: int = 0  # seconds


def has_active(runs):
    return any(run["status"] in ACTIVE_STATUSES for run in runs)


def cooldown_left(runs, now, cooldown_seconds):
    if not runs:
        return 0
    newest = max(datetime.fromisoformat(run["created_at"]) for run in runs)
    waited = (now - newest).total_seconds()
    return max(0, int(cooldown_seconds - waited))


def minutes(seconds):
    return max(1, round(seconds / 60))


def decide_wake(apply_runs, destroy_runs, now, cooldown_seconds):
    if has_active(destroy_runs):
        return Decision(False, 409, "destroy_running",
                        "The environment is shutting down. Try again when that has finished.")
    if has_active(apply_runs):
        return Decision(False, 409, "deploy_running",
                        "A deployment is already in progress. Check back in a few minutes.")
    wait = cooldown_left(apply_runs, now, cooldown_seconds)
    if wait:
        return Decision(False, 429, "cooldown",
                        f"A deployment ran recently. Please wait about {minutes(wait)} min.",
                        retry_after=wait)
    return Decision(True, 202, "started",
                    "Deployment started. It takes about 10 minutes, then reload this page.")


def decide_destroy(destroy_runs, now, cooldown_seconds):
    if has_active(destroy_runs):
        return Decision(False, 409, "destroy_running", "A shutdown is already in progress.")
    wait = cooldown_left(destroy_runs, now, cooldown_seconds)
    if wait:
        return Decision(False, 429, "cooldown",
                        f"A shutdown ran recently. Please wait about {minutes(wait)} min.",
                        retry_after=wait)
    return Decision(True, 202, "started",
                    "Shutdown started. This page stops responding in a few minutes.")


def decide_scheduled_destroy(destroy_runs):
    if has_active(destroy_runs):
        return Decision(False, 200, "destroy_running", "A shutdown is already in progress.")
    return Decision(True, 202, "started", "Scheduled shutdown started.")
