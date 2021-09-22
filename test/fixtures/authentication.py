import pytest

import subprocess
import google.auth

from google.cloud import secretmanager as sml


SERVICE = "unicodex"
REGION = "us-central1"
SECRET_NAME = "django_settings"

_, GOOGLE_CLOUD_PROJECT = google.auth.default()

sm = sml.SecretManagerServiceClient()

@pytest.fixture
def service_url():
    # Get Cloud Run service URL and auth token
    service_url = (
        subprocess.run(
            [
                "gcloud",
                "run",
                "services",
                "describe",
                SERVICE,
                "--platform",
                "managed",
                "--region",
                REGION,
                "--format",
                "value(status.url)",
                "--project",
                GOOGLE_CLOUD_PROJECT,
            ],
            stdout=subprocess.PIPE,
            check=True,
        )
        .stdout.strip()
        .decode()
    )
    yield service_url

@pytest.fixture
def auth_token(): 
    auth_token = (
        subprocess.run(
            [
                "gcloud",
                "auth",
                "print-identity-token",
                "--project",
                GOOGLE_CLOUD_PROJECT,
            ],
            stdout=subprocess.PIPE,
            check=True,
        )
        .stdout.strip()
        .decode()
    )

    yield auth_token


def get_secret_payload(secret_name):
    path = f"projects/{GOOGLE_CLOUD_PROJECT}/secrets/{secret_name}/versions/latest"
    return sm.access_secret_version(name=path).payload.data.decode("UTF-8")


@pytest.fixture
def get_admin_login():
    admin_username = get_secret_payload("SUPERUSER")
    admin_password = get_secret_payload("SUPERPASS")
    yield admin_username, admin_password

@pytest.fixture
def service_url():
    service_url = (
        subprocess.run(
            [
                "gcloud",
                "run",
                "services",
                "describe",
                SERVICE,
                "--platform",
                "managed",
                "--region",
                REGION,
                "--format=value(status.url)",
                "--project",
                GOOGLE_CLOUD_PROJECT,
            ],
            stdout=subprocess.PIPE,
            check=True,
        )
        .stdout.strip()
        .decode()
    )
    return service_url