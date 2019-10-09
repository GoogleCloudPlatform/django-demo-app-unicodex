# Setup Google Cloud Platform environment


*The steps listed below are common to doing anything on Google Cloud. If you run into any issues, you can find many step-by-step tutorials on the topic.*

In order to deploy on Google Cloud, you need to sign up. 

Go to [cloud.google.com](https://cloud.google.com/) and click "Get started". 

Once you have signed up, create a new Project.

Notes: 

* project names are *globally unique* -- no one else can have the same project name as you. 
* We're going to be referring to this name as `PROJECT_ID`. A lot. 

You will also need to setup this project against a Billing Account. 

---

We're also going to be using the command line utility for Google Cloud, `gcloud`, wherever possible. 

Go to the [`gcloud` install website](https://cloud.google.com/sdk/docs/#install_the_latest_cloud_tools_version_cloudsdk_current_version) and follow the instructions your operating system. 

To test your `gcloud` works and is up to date: 

```
gcloud --version
```

If you see a "Updates area available" prompt, follow those installation instructions. 

Next, we need to set our default project. 

```
export PROJECT_ID=YourProjectId
```

Setting this as an environment variable will mean when you copy and paste code from this documentation, it will Just Work(tm). Note that this variable will only be set for your current terminal. Run it again if you open a new terminal window. 

To tell `gcloud` about this project, we configure it: 

```
gcloud config set project $PROJECT_ID
```

You can check this setting by running: 

```
gcloud config list
```

Finally, we will be using a number of Google Cloud services in this tutorial. We can save time by enabling them ahead of time: 

```
gcloud services enable \
    run.googleapis.com \
    compute.googleapis.com \
    sql-component.googleapis.com \
    storage-component.googleapis.com \
    cloudbuild.googleapis.com \
    cloudkms.googleapis.com \
    storage-api.googleapis.com \
    cloudresourcemanager.googleapis.com
```

---

We are now ready to set us up some databases!

---

Next step: [Create a Cloud SQL Instance](20-setup-sql.md)