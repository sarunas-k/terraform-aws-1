"""Run: python3 -m unittest discover -s tests (from infra-control/)"""
import sys
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import control  # noqa: E402

NOW = datetime(2026, 11, 20, 12, 0, tzinfo=timezone.utc)
COOLDOWN = 600


def run(minutes_ago, status="completed", conclusion="success"):
    created = NOW - timedelta(minutes=minutes_ago)
    return {"created_at": created.isoformat(), "status": status, "conclusion": conclusion}


class WakeTests(unittest.TestCase):
    def test_first_ever_wake_starts(self):
        decision = control.decide_wake([], [], NOW, COOLDOWN)
        self.assertTrue(decision.dispatch)
        self.assertEqual(decision.status, 202)

    def test_apply_running_is_refused(self):
        decision = control.decide_wake([run(3, "in_progress", None)], [], NOW, COOLDOWN)
        self.assertFalse(decision.dispatch)
        self.assertEqual((decision.status, decision.key), (409, "deploy_running"))

    def test_queued_and_pending_count_as_running(self):
        for status in ("queued", "waiting", "pending", "requested"):
            decision = control.decide_wake([run(1, status, None)], [], NOW, COOLDOWN)
            self.assertEqual(decision.key, "deploy_running", status)

    def test_destroy_running_is_refused(self):
        decision = control.decide_wake([run(120)], [run(2, "in_progress", None)], NOW, COOLDOWN)
        self.assertEqual((decision.status, decision.key), (409, "destroy_running"))

    def test_cooldown_after_recent_apply(self):
        decision = control.decide_wake([run(3, conclusion="failure")], [], NOW, COOLDOWN)
        self.assertFalse(decision.dispatch)
        self.assertEqual((decision.status, decision.key), (429, "cooldown"))
        self.assertEqual(decision.retry_after, 420)

    def test_cooldown_uses_newest_run(self):
        decision = control.decide_wake([run(300), run(2), run(60)], [], NOW, COOLDOWN)
        self.assertEqual(decision.key, "cooldown")

    def test_old_apply_allows_wake(self):
        decision = control.decide_wake([run(30)], [], NOW, COOLDOWN)
        self.assertTrue(decision.dispatch)

    def test_recent_destroy_does_not_block_wake(self):
        decision = control.decide_wake([run(60)], [run(1)], NOW, COOLDOWN)
        self.assertTrue(decision.dispatch)


class DestroyTests(unittest.TestCase):
    def test_destroy_starts(self):
        decision = control.decide_destroy([], NOW, COOLDOWN)
        self.assertTrue(decision.dispatch)

    def test_destroy_running_is_refused(self):
        decision = control.decide_destroy([run(1, "queued", None)], NOW, COOLDOWN)
        self.assertEqual((decision.status, decision.key), (409, "destroy_running"))

    def test_destroy_cooldown(self):
        decision = control.decide_destroy([run(4)], NOW, COOLDOWN)
        self.assertEqual((decision.status, decision.key), (429, "cooldown"))

    def test_old_destroy_allows_destroy(self):
        decision = control.decide_destroy([run(20)], NOW, COOLDOWN)
        self.assertTrue(decision.dispatch)


class ScheduledDestroyTests(unittest.TestCase):
    def test_runs_without_history(self):
        self.assertTrue(control.decide_scheduled_destroy([]).dispatch)

    def test_runs_even_right_after_another_destroy(self):
        self.assertTrue(control.decide_scheduled_destroy([run(1)]).dispatch)

    def test_skipped_while_a_destroy_is_running(self):
        decision = control.decide_scheduled_destroy([run(5, "in_progress", None)])
        self.assertFalse(decision.dispatch)
        self.assertEqual(decision.status, 200)


if __name__ == "__main__":
    unittest.main()
