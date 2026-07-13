#!/usr/bin/env python3

import requests
import subprocess
import time
import sys

ALERTMANAGER_URL = "http://localhost:9093/api/v2/alerts"
TARGET_URL = "http://localhost:8080/"


def check_alertmanager(alert_name):
    """Check if the specified alert is currently active."""
    try:
        response = requests.get(ALERTMANAGER_URL, timeout=5)
        response.raise_for_status()

        alerts = response.json()

        for alert in alerts:
            if (
                alert["labels"].get("alertname") == alert_name
                and alert["status"]["state"] == "active"
            ):
                return True

        return False

    except requests.RequestException as error:
        print(f"❌ Failed to query AlertManager: {error}")
        return False


def generate_load(duration_seconds, concurrency):
    # Start a hey load test and return the running process.

    duration = f"{duration_seconds}s"
    command = ["hey", "-z", duration, "-c", str(concurrency), TARGET_URL]
    return subprocess.Popen(command)


def main():
    print("Checking AlertManager is reachable...")

    MAX_WAIT_SECONDS = 360
    start_time = time.time()

    try:
        response = requests.get(ALERTMANAGER_URL, timeout=5)
        response.raise_for_status()

    except requests.RequestException:
        print("❌ AlertManager is not reachable.")
        sys.exit(1)

    print("✅ AlertManager is reachable.\n")
    print("Generating load to trigger HPAMaxedOut alert...\n")

    process = generate_load(300, 200)

    while process.poll() is None:

        if time.time() - start_time > MAX_WAIT_SECONDS:
            print("\n❌ Timeout waiting for alert")
            process.terminate()
            sys.exit(1)

        if check_alertmanager("HPAMaxedOut"):
            print("\n✅ HPAMaxedOut alert fired successfully")

            process.terminate()
            sys.exit(0)

        print(f"⏳ Checking for HPAMaxedOut alert... (elapsed: {int(time.time()-start_time)}s)")
        time.sleep(30)

    print("\n❌ Alert did not fire within expected window")
    sys.exit(1)


if __name__ == "__main__":
    main()
