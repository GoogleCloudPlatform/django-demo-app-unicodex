# Setup Google Cloud Platform environment


*The steps listed below are common to doing anything on Google Cloud. If you run into any issues, you can find many step-by-step tutorials on the topic.*

In order to deploy on Google Cloud, you need to sign up (if you haven't already).

To sign up: to [cloud.google.com](https://cloud.google.com/) and click "Get started". 

Once you have signed up, you need to create a new project.

Notes: 

* Project names are *globally unique* -- no one else can have the same project name as you. 
* Project names cannot be changed after they have been created.
* We're going to be referring to this name as `PROJECT_ID`. A lot. 

You will also need to setup this project against a Billing Account. 

---

### 🤔 Think about how long you want to keep this demo

If you happen to already have a Google Cloud Platform account, create a new project for this tutorial demo. 

That way, [cleanup](90-cleanup.md) will be much easier. 

---

We're also going to be using the command line utility for Google Cloud, `gcloud`, wherever possible. 

Go to the [`gcloud` install website](https://cloud.google.com/sdk/docs/#install_the_latest_cloud_tools_version_cloudsdk_current_version) and follow the instructions your operating system. 

To test your `gcloud` works and is up to date: 

```shell,exclude
gcloud --version
```

If you see a "Updates area available" prompt, follow those installation instructions. 

Next, we need to set our default project. 

```shell
export PROJECT_ID=YourProjectID
```

Setting this as an environment variable will mean when you copy and paste code from this documentation, it will Just Work(tm). Note that this variable will only be set for your current terminal. Run it again if you open a new terminal window. 

To tell `gcloud` about this project, we configure it: 

```shell
gcloud config set project $PROJECT_ID
```

You can check this setting by running: 

```shell,exclude
gcloud config list
```

When we get to the Cloud Run sections, we'll be using the managed Cloud Run platform. To prevent us from having to define that each time (`--platform managed`), we can set the default now: 

```shell
gcloud config set run/platform managed
```

Finally, we will be using a number of Google Cloud services in this tutorial. We can save time by enabling them ahead of time: 

```shell
gcloud services enable \
    run.googleapis.com \
    compute.googleapis.com \
    sql-component.googleapis.com \
    sqladmin.googleapis.com \
    storage-component.googleapis.com \
    cloudbuild.googleapis.com \
    cloudkms.googleapis.com \
    storage-api.googleapis.com \
    cloudresourcemanager.googleapis.com
```

This may take a few minutes to complete. 

---

We are now ready to set us up some databases!

---

Next step: [Create a Cloud SQL Instance](20-setup-sql.md)