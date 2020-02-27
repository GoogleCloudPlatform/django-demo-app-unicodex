# Setup Google Cloud Platform environment

*The steps listed below are common to doing anything on Google Cloud. If you run into any issues, you can find many step-by-step tutorials on the topic.*

---

In order to deploy on Google Cloud, you need to sign up (if you haven't already).

To sign up, go to [cloud.google.com](https://cloud.google.com/) and click "Get started". 

Once you have signed up, you need to create a new project.

Notes: 

* Project names are *globally unique* -- no one else can have the same project name as you. 
* Project names cannot be changed after they have been created.
* We're going to be referring to this name as `PROJECT_ID`. A lot. 

You will also need to setup this project against a Billing Account. Some of the components we will provision will cost money, but new customers do get [free credits](https://cloud.google.com/free)

---

### 🤔 Think about how long you want to keep this demo

If you happen to already have a Google Cloud Platform account, create a new project for this tutorial demo. Don't use an existing project. That way, [cleanup](90-cleanup.md) will be much easier. 

---

We're also going to be using the command line utility (CLI) for Google Cloud, `gcloud`, wherever possible. 

Go to the [`gcloud` install website](https://cloud.google.com/sdk/docs/#install_the_latest_cloud_tools_version_cloudsdk_current_version) and follow the instructions your operating system. 

To test your `gcloud` works and is up to date: 

```shell,exclude
gcloud --version
```

If you see a "Updates area available" prompt, follow those installation instructions. 

Next, we need to set our project ID in both the command-line and as an environment variable. 


Setting this as an environment variable will mean when you copy and paste code from this documentation, it will Just Work(tm). Note that this variable will only be set for your current terminal. Run it again if you open a new terminal window. 

```shell
export PROJECT_ID=YourProjectID
gcloud config set project $PROJECT_ID
```

You can check your current project settings by running: 

```shell,exclude
gcloud config list
```

When we get to the Cloud Run sections, we'll be using the managed Cloud Run platform. To prevent us from having to define that each time (`--platform managed`), we can set the default now: 

```shell
gcloud config set run/platform managed
```

We'll also want to default to the `us-central1` region, which we can also tell `gcloud` about. 

```shell
export REGION=us-central1
gcloud config set run/region $REGION
```

---

Finally, we will be using a number of Google Cloud services in this tutorial. We can save time by enabling them ahead of time: 

```shell
gcloud services enable \
    run.googleapis.com \
    iam.googleapis.com \
    compute.googleapis.com \
    sql-component.googleapis.com \
    sqladmin.googleapis.com \
    storage-component.googleapis.com \
    cloudbuild.googleapis.com \
    cloudkms.googleapis.com \
    storage-api.googleapis.com \
    cloudresourcemanager.googleapis.com \
    secretmanager.googleapis.com
```

This operation may take a few minutes to complete. 

---

While we're here making all these project configurations, we'll also take the time to setup our Service Account. 

ℹ️ While in theory this is not required, it good practice to be explicit when setting up complex systems like this to have named service accounts. This ensures that we know what's going on at a glance, and prevents us having to use the 'default service accounts' that might have more permissions than we want. 

Since this is the Unicodex project, we'll create a service account called unicodex. 

```shell
export SERVICE_NAME=unicodex

gcloud iam service-accounts create $SERVICE_NAME \
  --display-name "$SERVIE_NAME service account"
```


Now that this account exists, we'll be referring to it later by it's email. We can take the time to store that now: 

```shell
export CLOUDRUN_SA=${SERVICE_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
```

(In this case "SA" refers to "Service Account".)

We'll also need to tell this account what it's allowed to access. It needs to be allowed to [connect to our database](https://cloud.google.com/sql/docs/postgres/connect-run#configuring), and be our Cloud Run administrator:

```shell
for role in cloudsql.client run.admin; do
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$CLOUDRUN_SA \
    --role roles/${role}
done
```

We wouldn't normally have to be this explicit, but since we created a new service account from scratch, we need to give it a few specific roles. 

---

ℹ️ A note on permissions: 

This guided deployment makes liberal use of `gcloud`. When you setup `gcloud`, you configured it to run as you. That is, youremail@yourdomain.com. You are, by default, a member of the ["Owner" role](https://cloud.google.com/iam/docs/understanding-roles). Given this, you have permission to do *anything*. So for a lot of the `gcloud` commands you run, you have the rights to do that. But when we start getting into the [automation parts](50-first-deployment.md), we will be updating components that already exist. Therefore, we only need the 'update' permissions (as opposed to 'create'). (It takes more permissions to create a Cloud Run service than it does to update one that already exists, for example.)

We have another way to deploy this demo project, using [terraform](../terraform/README.md). This automation method assumes that there is no `gcloud`, and the entire setup is run through terraform. Therefore, the permissions used are different: terraform needs to be able to create and also update components. 

If you are after ways in which to limit access across service accounts and IAM bindings in your own project, keep this implementation detail in mind.  

---

Now we've setup our environment, it's time to setup some services. First up: databases!

---

Next step: [Create a Cloud SQL Instance](20-setup-sql.md)
