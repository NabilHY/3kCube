#!/usr/bin/env python3
"""
CD test helper – validates ArgoCD reconciliation in a dev namespace.

Usage:
    python test-cd.py delete   # Delete all resources in dev; ArgoCD should recreate them
    python test-cd.py update   # Toggle image tag between v1 ↔ v2, commit & push
"""

import argparse
import os
import re
import subprocess
import sys
import time

import requests

ENDPOINT_URL = "http://playground.localhost:8000"
FILE_PATH = "../confs/app/deployment.yml"
IMAGE_PATTERN = re.compile(r"(image:\s*goslinabil/3kcube:)(v[12])")

RECONCILE_WAIT = 45  # seconds to wait for ArgoCD to reconcile


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def fetch_endpoint(label: str = "") -> None:
    """Hit the playground endpoint and print the response."""
    prefix = f"[{label}] " if label else ""
    try:
        response = requests.get(ENDPOINT_URL, timeout=10)
        response.raise_for_status()
        print(f"{prefix}Endpoint responded: {response.text.strip()}")
    except requests.exceptions.RequestException as e:
        print(f"{prefix}Endpoint unreachable: {e}")


def detect_current_version() -> str:
    """Read deployment.yml and return the current image tag (v1 or v2)."""
    with open(FILE_PATH, "r") as fh:
        content = fh.read()
    match = IMAGE_PATTERN.search(content)
    if not match:
        sys.exit(
            f"ERROR: Could not find image tag matching {IMAGE_PATTERN.pattern} in {FILE_PATH}"
        )
    return match.group(2)


def toggle_version(current: str) -> str:
    """Return the opposite version tag."""
    return "v2" if current == "v1" else "v1"


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------


def action_update() -> None:
    """Toggle the image version in deployment.yml, commit, and push."""
    current = detect_current_version()
    target = toggle_version(current)
    print(f"Current image tag: {current}  →  switching to: {target}")

    # Read, replace, write
    with open(FILE_PATH, "r") as fh:
        content = fh.read()
    new_content = IMAGE_PATTERN.sub(rf"\g<1>{target}", content)
    with open(FILE_PATH, "w") as fh:
        fh.write(new_content)
    print(f"Updated {FILE_PATH}")
    # Git commit & push — run from the submodule directory (confs/app)
    # so that push targets the iot-p3-nhayoun origin, not 3kCube.
    repo_dir = os.path.dirname(os.path.abspath(FILE_PATH))
    abs_file = os.path.abspath(FILE_PATH)
    try:
        subprocess.run(["git", "add", abs_file], cwd=repo_dir, check=True)
        subprocess.run(
            ["git", "commit", "-m", f"chore: bump deployment image to {target}"],
            cwd=repo_dir,
            check=True,
        )
        subprocess.run(
            ["git", "push", "-u", "origin", "HEAD"], cwd=repo_dir, check=True
        )
        print("Changes pushed successfully")
    except subprocess.CalledProcessError as e:
        sys.exit(f"Git operation failed: {e}")


def action_delete() -> None:
    """Delete all deployments, services and pods in the dev namespace."""
    print("Deleting all deployments, services and pods in dev namespace …")
    try:
        subprocess.run(
            ["kubectl", "delete", "deployments,services,pods", "--all", "-n", "dev"],
            check=True,
        )
        print("dev namespace wiped — ArgoCD should reconcile")
    except subprocess.CalledProcessError as e:
        sys.exit(f"kubectl command failed: {e}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Test ArgoCD continuous-delivery pipeline"
    )
    parser.add_argument(
        "action",
        choices=["delete", "update"],
        help="'delete' wipes dev resources; 'update' toggles the image tag",
    )
    args = parser.parse_args()

    print("=== CD Test Workflow ===\n")

    fetch_endpoint("before")

    if args.action == "update":
        action_update()
    elif args.action == "delete":
        action_delete()

    print(f"\nWaiting {RECONCILE_WAIT}s for ArgoCD to reconcile …")
    time.sleep(RECONCILE_WAIT)

    fetch_endpoint("after")

    print("\n=== Workflow Complete ===")


if __name__ == "__main__":
    main()
