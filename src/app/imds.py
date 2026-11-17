import logging
import urllib.request

logger = logging.getLogger("app.imds")

IMDS_URL = "http://169.254.169.254/latest"
IMDS_TIMEOUT_SECONDS = 2


def fetch_availability_zone() -> str:
    """Read the instance AZ from IMDSv2. Returns "unknown" outside EC2 or on any error."""
    try:
        token_request = urllib.request.Request(
            f"{IMDS_URL}/api/token",
            method="PUT",
            headers={"X-aws-ec2-metadata-token-ttl-seconds": "60"},
        )
        with urllib.request.urlopen(token_request, timeout=IMDS_TIMEOUT_SECONDS) as response:
            token = response.read().decode()

        az_request = urllib.request.Request(
            f"{IMDS_URL}/meta-data/placement/availability-zone",
            headers={"X-aws-ec2-metadata-token": token},
        )
        with urllib.request.urlopen(az_request, timeout=IMDS_TIMEOUT_SECONDS) as response:
            return response.read().decode().strip()
    except Exception as error:  # noqa: BLE001 - any failure falls back to "unknown"
        logger.warning("Could not read availability zone from IMDS: %s", error)
        return "unknown"
