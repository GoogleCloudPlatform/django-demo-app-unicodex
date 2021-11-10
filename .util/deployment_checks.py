import json
import subprocess
from io import StringIO
from urllib.parse import urlparse

import click
import googleapiclient
import httpx
from bs4 import BeautifulSoup as bs4
from dotenv import dotenv_values
from google.api_core import exceptions
from google.cloud import secretmanager as sml
from googleapiclient.discovery import build

from cliformatting import echo, error, header, result, summary

# TODO(glasnt): more checks as required


def get_service(project, service_name, region):
    run = build("run", "v1")
    fqname = f"projects/{project}/locations/{region}/services/{service_name}"
    service = run.projects().locations().services().get(name=fqname).execute()
    return service


def get_sa(service):
    return service["spec"]["template"]["spec"]["serviceAccountName"]


def check_run(service):
    header(f"Service configuration checks")

    sn = service["metadata"]["name"]
    result(f"Service {sn} exists")


def check_sa(service):
    sa = get_sa(service)
    echo(f"Associated service account: {sa}")

    result(
        f"Associated service account is not the default service account",
        details="Ensure a custom service account is associated to the service",
        success=("compute-" not in sa),
    )


def check_bindings(service, project):
    sa = get_sa(service)
    echo(f"Associated service account (SA): {sa}")

    success = True
    crm = build("cloudresourcemanager", "v1")
    iam = crm.projects().getIamPolicy(resource=f"{project}").execute()
    for binding in iam["bindings"]:
        if binding["role"] == "roles/owner":
            for member in binding["members"]:
                if member == sa:
                    success = False
    result(
        "SA doesn't have Owner role",
        details="Remove service account from having Owner role",
        success=success,
    )


def check_roles(service, project):
    sa = f"serviceAccount:{get_sa(service)}"
    crm = build("cloudresourcemanager", "v1")
    iam = crm.projects().getIamPolicy(resource=f"{project}").execute()

    required_roles = ["roles/run.admin", "roles/cloudsql.client"]

    member_roles = [b["role"] for b in iam["bindings"] if sa in b["members"]]

    for role in required_roles:
        result(
            f"SA has {role}",
            details=f"Ensure SA has {role}",
            success=(role in member_roles),
        )


def cleanhtml(raw_html):
    soup = bs4(raw_html, "html.parser")
    for tag in soup():
        for attribute in ["class", "id", "name", "style"]:
            del tag[attribute]

    return "Page preview: " + " ".join(soup.find_all(text=True)).replace(
        " ", ""
    ).replace("\n", " ")


def check_unicodex(project, service):
    header("Deployed service checks")

    fixture_code = "1F44B"
    fixture_slug = f"/u/{fixture_code}"
    login_slug = "/admin/login/?next=/admin/"
    model_admin_slug = "/admin/unicodex/codepoint/"

    if "url" not in service["status"].keys():
        message = service["status"]["conditions"][0]["message"]
        result(f"Service does not have a deployed URL: {message}", success=False)
    else:
        url = service["status"]["url"]
        echo(f"Service deployment URL: {url}")

        try:
            response = httpx.get(url, timeout=30)

        except httpx.ReadTimeout as e:
            result(e, success=False)
            return

        print(cleanhtml(response.text))
        if response.status_code == 200:
            result("Index page loaded successfully")
        else:
            result(
                f"Index page returns an error: {response.status_code}", success=False
            )

        if "Unicodex" in response.text:
            result("Index page contains 'Unicodex'")
        else:
            result("Index page does not contain the string 'Unicodex'", success=False)

        fixture = httpx.get(url + fixture_slug)
        print(cleanhtml(fixture.text))

        admin = httpx.get(url + login_slug)
        if not admin.is_error:
            result(f"Django admin returns status okay ({admin.status_code})")
        else:
            result(f"Django admin returns an error: {admin.status_code}", success=False)

        if "Log in" in admin.text and "Django administration" in admin.text:
            result("Django admin login screen successfully loaded")
        else:
            result("Django admin login not found", success=False, details=admin.text)

        headers = {"Referer": url}
        with httpx.Client(headers=headers, follow_redirects=True, timeout=30) as client:

            # Login
            admin_username = get_secret(project, "SUPERUSER")
            admin_password = get_secret(project, "SUPERPASS")

            header("Test Django Admin")
            client.get(url + login_slug)
            response = client.post(
                url + login_slug,
                data={
                    "username": admin_username,
                    "password": admin_password,
                    "csrfmiddlewaretoken": client.cookies["csrftoken"],
                },
            )
            assert not response.is_error
            assert "Site administration" in response.text
            assert "Codepoints" in response.text
            result(f"Django Admin logged in")

            # Try admin action
            response = client.post(
                url + model_admin_slug,
                data={
                    "action": "generate_designs",
                    "_selected_action": 1,
                    "csrfmiddlewaretoken": client.cookies["csrftoken"],
                },
            )
            assert not response.is_error
            assert "Imported vendor versions" in response.text
            result(f"Django Admin action completed")

            # check updated feature
            response = client.get(url + f"/u/{fixture_code}")
            assert fixture_code in response.text
            assert "Android" in response.text
            result(f"Django Admin action verified")

            print(cleanhtml(response.text))


def get_secret(project, secret_name):
    sm = sml.SecretManagerServiceClient()  # using static library
    secret_path = f"projects/{project}/secrets/{secret_name}/versions/latest"
    try:
        payload = sm.access_secret_version(name=secret_path).payload.data.decode(
            "UTF-8"
        )
        return payload
    except exceptions.PermissionDenied as e:
        result(f"Secret error: {e}", success=False)
        return ""


def parse_secrets(values):
    secrets = {}
    secrets["dburl"] = urlparse(values["DATABASE_URL"])
    secrets["dbuser"] = secrets["dburl"].netloc.split(":")[0]
    secrets["dbinstance"], secrets["dbname"] = secrets["dburl"].path.split("/")[3:]
    secrets["media_bucket"] = values["GS_BUCKET_NAME"]
    return secrets


def check_secrets(values):
    header("Settings checks")
    for key in ["DATABASE_URL", "GS_BUCKET_NAME", "SECRET_KEY"]:
        result(f"{key} is defined", success=(key in values.keys()))


def check_bucket(media_bucket):
    header("Object storage checks")
    sapi = build("storage", "v1")
    try:
        bucket = sapi.buckets().get(bucket=media_bucket).execute()
        result(f"Storage bucket {bucket['name']} exists in {bucket['location']}")
    except googleapiclient.errors.HttpError as e:
        result(f"Storage bucket error {e}", success=False)
    # TODO check bucket permissions.


def check_database(project, service, secrets):

    header("Database checks")
    database_name = service["spec"]["template"]["metadata"]["annotations"][
        "run.googleapis.com/cloudsql-instances"
    ]
    echo(f"Associated database: {database_name}")
    _, dbregion, dbinstance = database_name.split(":")

    result(
        f"Associated database instance matches secret connection URL instance",
        success=(secrets["dbinstance"] == database_name),
    )

    dbapi = build("sqladmin", "v1beta4")
    instance = dbapi.instances().get(project=project, instance=dbinstance).execute()
    result(
        f"Instance exists: {instance['name']}, running {instance['databaseVersion']}"
    )

    database = (
        dbapi.databases()
        .get(project=project, instance=dbinstance, database=secrets["dbname"])
        .execute()
    )
    result(f"Database exists: {database['name']}, collation {database['collation']}")

    users = dbapi.users().list(project=project, instance=dbinstance).execute()
    result(
        f"User exists: {secrets['dbuser']}",
        details=users["items"],
        success=(secrets["dbuser"] in [user["name"] for user in users["items"]]),
    )


def check_deploy(project, service_name, region, secret_name):
    click.secho(f"🛠  Checking {service_name} in {region} in {project}", bold=True)

    service = get_service(project, service_name, region)

    check_run(service)
    check_bindings(service, project)

    check_roles(service, project)
    check_unicodex(project, service)

    secret_env = get_secret(project, secret_name)

    if secret_env:
        # https://github.com/theskumar/python-dotenv#in-memory-filelikes
        values = dotenv_values(stream=StringIO(secret_env))
        check_secrets(values)
        secrets = parse_secrets(values)

        check_bucket(secrets["media_bucket"])

        check_database(project, service, secrets)

    summary()


def gcloud(call):
    """
    WARNING: should only be used when no Python API exists.
    Calls out to gcloud, and returns a dict of the json result.

    Sample invocation:
    service = gcloud(f"run services describe {service}")
    sa = service["spec"]["template"]["spec"]["serviceAccountName"]
    """
    params = ["gcloud"] + call.split(" ") + ["--format", "json"]
    resp = subprocess.run(params, capture_output=True)
    if resp.returncode != 0:
        error(f"gcloud {call} returned {resp.returncode}", details=resp.stderr)
    return json.loads(resp.stdout)
