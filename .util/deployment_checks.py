from cliformatting import header, result, summary, error, echo
import json
import click
import httpx
import subprocess
from googleapiclient.discovery import build
from google.cloud import secretmanager_v1beta1 as sml
from dotenv import dotenv_values
from io import StringIO
from urllib.parse import urlparse

"""
SETUP:

googleapiclient.discovery requires authentication, so setup a dedicated service
account:

gcloud iam service-accounts create robot-account \
    --display-name "Robot account"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:robot-account@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/owner
gcloud iam service-accounts keys create ~/robot-account-key.json \
    --iam-account robot-account@${PROJECT_ID}.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS=~/robot-account-key.json
"""

# TODO(glasnt): more checks as required


def check_deploy(project, service_name, region, secret_name):
    click.secho(f"🛠  Checking {service_name} in {region} in {project}", bold=True)

    header(f"Service configuration checks")

    api = build("run", "v1")
    fqname = f"projects/{project}/locations/{region}/services/{service_name}"
    service = api.projects().locations().services().get(name=fqname).execute()

    sn = service["metadata"]["name"]
    result(f"Service {sn} exists")

    sa = service["spec"]["template"]["spec"]["serviceAccountName"]
    echo(f"Associated service account: {sa}")

    ###
    result(
        f"Associated service account is not default",
        details="Ensure a custom service account is associated to the service",
        success=("compute-" not in sa),
    )

    ###
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

    ###
    header("Deployed service checks")
    url = service["status"]["url"]
    echo(f"Service deployment URL: {url}")

    page = httpx.get(url)
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

    ###
    header("Secret checks")
    sm = sml.SecretManagerServiceClient()  # using static library
    secret_path = f"projects/{project}/secrets/{secret_name}/versions/latest"
    payload = sm.access_secret_version(secret_path).payload.data.decode("UTF-8")

    result(f"Secret {secret_path} exist")
    # https://github.com/theskumar/python-dotenv#in-memory-filelikes
    values = dotenv_values(stream=StringIO(payload))
    for key in ["DATABASE_URL", "GS_BUCKET_NAME", "SECRET_KEY"]:
        result(f"{key} is defined", success=(key in values.keys()))

    secret_dburl = urlparse(values["DATABASE_URL"])
    secret_dbuser = secret_dburl.netloc.split(":")[0]
    secret_dbinstance, secret_dbname = secret_dburl.path.split("/")[3:]
    media_bucket = values["GS_BUCKET_NAME"]

    ###
    header("Object storage checks")
    sapi = build("storage", "v1")
    bucket = sapi.buckets().get(bucket=media_bucket).execute()
    result(f"Storage bucket {bucket['name']} exists in {bucket['location']}")
    # TODO check bucket permissions.

    ###
    header("Database checks")
    database_name = service["spec"]["template"]["metadata"]["annotations"][
        "run.googleapis.com/cloudsql-instances"
    ]
    echo(f"Associated database: {database_name}")
    _, dbregion, dbinstance = database_name.split(":")

    result(
        f"Associated database instance matches secret connection URL instance",
        success=(secret_dbinstance == database_name),
    )

    dbapi = build("sql", "v1beta4")
    instance = dbapi.instances().get(project=project, instance=dbinstance).execute()
    result(
        f"Instance exists: {instance['name']}, running {instance['databaseVersion']}"
    )

    database = (
        dbapi.databases()
        .get(project=project, instance=dbinstance, database=secret_dbname)
        .execute()
    )
    result(f"Database exists: {database['name']}, collation {database['collation']}")

    users = dbapi.users().list(project=project, instance=dbinstance).execute()
    result(
        f"User exists: {secret_dbuser}",
        details=users["items"],
        success=(secret_dbuser in [user["name"] for user in users["items"]]),
    )

    # All checks complete; show results.
    summary()


"""
WARNING: should only be used when no Python API exists.
Calls out to gcloud, and returns a dict of the json result.

Sample invocation:
service = gcloud(f"run services describe {service}")
sa = service["spec"]["template"]["spec"]["serviceAccountName"]
"""


def gcloud(call):
    params = ["gcloud"] + call.split(" ") + ["--format", "json"]
    resp = subprocess.run(params, capture_output=True)
    if resp.returncode != 0:
        error(f"gcloud {call} returned {resp.returncode}", details=resp.stderr)
    return json.loads(resp.stdout)
