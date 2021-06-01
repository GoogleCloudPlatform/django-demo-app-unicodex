from cliformatting import header, result, summary, error, echo
import json
import click
import httpx
import subprocess
from googleapiclient.discovery import build
import googleapiclient
from google.cloud import secretmanager_v1 as sml
from dotenv import dotenv_values
from io import StringIO
from urllib.parse import urlparse

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
        f"Associated service account is not default",
        details="Ensure a custom service account is associated to the service",
        success=("compute-" not in sa),
    )


def check_bindings(service, project):

    sa = get_sa(service)
    success = True
    crm = build("cloudresourcemanager", "v1")
    iam = crm.projects().getIamPolicy(resource=f"{project}").execute()
    for binding in iam["bindings"]:
        if binding["role"] == "roles/owner":
            echo("Checking roles/owner bindings")
            for member in binding["members"]:
                echo(member, indent="> ")
                if member == sa:
                    success = True
    result(
        "Associated service account permissions aren't owner",
        details="Ensure the service account isn't using owner permissions",
        success=success,
    )


def check_unicodex(service):

    header("Deployed service checks")
    if "url" not in service["status"].keys():
        message = service["status"]["conditions"][0]["message"]
        result(f"Service does not have a deployed URL: {message}", success=False)
    else:
        url = service["status"]["url"]
        echo(f"Service deployment URL: {url}")

        try:
            page = httpx.get(url, timeout=30)

        except httpx.ReadTimeout as e:
            result(e, success=False)
            return

        if page.status_code == 200:
            result("Index page loaded successfully")
        else:
            result(f"Index page returns an error: {page.status_code}", success=False)

        if "Unicodex" in page.text:
            result("Index page contains 'Unicodex'")
        else:
            result("Index page does not contain the string 'Unicodex'", success=False)

        admin = httpx.get(url + "/admin")
        if admin.status_code == 200:
            result("Django admin returns status 200")
        else:
            result(f"Django admin returns an error: {page.status_code}", success=False)

        if "Log in" in admin.text and "Django administration" in admin.text:
            result("Django admin login screen successfully loaded")
        else:
            result("Django admin login not found", success=False, details=admin.text)


def get_secret(project, secret_name):

    sm = sml.SecretManagerServiceClient()  # using static library
    secret_path = f"projects/{project}/secrets/{secret_name}/versions/latest"
    payload = sm.access_secret_version(name=secret_path).payload.data.decode("UTF-8")

    result(f"Secret {secret_path} exist")

    # https://github.com/theskumar/python-dotenv#in-memory-filelikes
    values = dotenv_values(stream=StringIO(payload))
    return values


def parse_secrets(values):

    secrets = {}
    secrets["dburl"] = urlparse(values["DATABASE_URL"])
    secrets["dbuser"] = secrets["dburl"].netloc.split(":")[0]
    secrets["dbinstance"], secrets["dbname"] = secrets["dburl"].path.split("/")[3:]
    secrets["media_bucket"] = values["GS_BUCKET_NAME"]
    return secrets


def check_secrets(values):
    header("Secret value checks")
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
    check_unicodex(service)

    values = get_secret(project, secret_name)
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
