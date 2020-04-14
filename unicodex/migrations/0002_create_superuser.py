from django.db import migrations

import os

def createsuperuser(apps, schema_editor):
    settings = ["SUPERUSER", "SUPERPASS"]
    if not all (k in os.environ.keys() for k in set(settings)):
        import sm_helper
        secrets = sm_helper.access_secrets(settings)
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
