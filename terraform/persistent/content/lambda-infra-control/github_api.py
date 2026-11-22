"""GitHub REST API calls"""
import json
import urllib.error
import urllib.parse
import urllib.request

API_URL = "https://api.github.com"
API_VERSION = "2026-03-10"
TIMEOUT_SECONDS = 10


class GitHubError(Exception):
    """Status 0 means GitHub could not be reached."""

    def __init__(self, status, detail):
        super().__init__(f"GitHub returned {status}: {detail}")
        self.status = status


def _call(method, path, token, body=None):
    data = json.dumps(body).encode() if body is not None else None
    request = urllib.request.Request(
        API_URL + path,
        data=data,
        method=method,
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "User-Agent": "infra-control-lambda",
            "X-GitHub-Api-Version": API_VERSION,
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
            raw = response.read()
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")[:200]
        raise GitHubError(error.code, detail) from error
    except (urllib.error.URLError, TimeoutError) as error:
        raise GitHubError(0, str(error)) from error
    return json.loads(raw) if raw else {}


def list_runs(repo, workflow_file, token, branch="main"):
    query = urllib.parse.urlencode({"branch": branch, "per_page": 20})
    path = f"/repos/{repo}/actions/workflows/{workflow_file}/runs?{query}"
    return _call("GET", path, token)["workflow_runs"]


def dispatch(repo, workflow_file, token, ref="main", inputs=None):
    """Returns the run's web URL, or None."""
    body = {"ref": ref}
    if inputs:
        body["inputs"] = inputs
    path = f"/repos/{repo}/actions/workflows/{workflow_file}/dispatches"
    return _call("POST", path, token, body).get("html_url")
