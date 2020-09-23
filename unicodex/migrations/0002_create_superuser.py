import os

from django.db import migrations

import google.auth
from google.cloud import secretmanager_v1 as sm


def access_secrets(secret_keys):
    secrets = {}
    _, project = google.auth.default()

    if project:
        client = sm.SecretManagerServiceClient()

        for s in secret_keys:
            name = f"projects/{project}/secrets/{s}/versions/latest"
            payload = client.access_secret_version(name=name).payload.data.decode("UTF-8")
            secrets[s] = payload

    return secrets


def createsuperuser(apps, schema_editor):
    settings = ["SUPERUSER", "SUPERPASS"]
    if not all (k in os.environ.keys() for k in set(settings)):
        secrets = access_secrets(settings)
        username = secrets["SUPERUSER"]
        password = secrets["SUPERPASS"]
    else:
        username = os.environ["SUPERUSER"]
        password = os.environ["SUPERPASS"]

    # Create a new user using acquired password
    from django.contrib.auth.models import User

    User.objects.create_superuser(username, password=password)


class Migration(migrations.Migration):

    dependencies = [
        ("unicodex", "0001_initial"),
    ]

    operations = [migrations.RunPython(createsuperuser)]
