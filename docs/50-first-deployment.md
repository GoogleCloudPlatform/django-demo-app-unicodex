# First Deployment

*In this section, we'll create our first deployment.*

**We're nearly there!**

We're up to deploying our project for the first time!

This is going to be a bit complicated at first, but the work we do here will make every other deployment much simpler. 

You'll remember way back when we were [testing locally](00-test-local.md) we built two images: a `web` image and a `db` image. 

`db` will be replaced with the proper PostgreSQL database we've [already setup](20-setup-sql.md). 

So we just need to build the other image!

For that, we'll be using Cloud Build. This is a similar process to `docker build .`, but this will build the image on Google Cloud itself, and publish the image to the Google Cloud image repository, `gcr.io`. 

If you haven't already done so, you'll need to clone the code into a local copy: 

```shell
git clone https://github.com/GoogleCloudPlatform/django-demo-app-unicodex
cd django-demo-app-unicodex
```

Then, build the image using the `gcloud` command:

```shell
gcloud builds submit --tag gcr.io/$PROJECT_ID/unicodex .
```

This will build the image much like Docker might locally, but within Google Cloud (no need to install Docker locally!)

Then, we can (finally!) create our Cloud Run service using this image. We'll also tell it all about the database we setup earlier, and all those secrets: 

```shell
gcloud run deploy unicodex \
    --allow-unauthenticated \
    --image gcr.io/$PROJECT_ID/unicodex \
    --update-env-vars DATABASE_URL=berglas://${BERGLAS_BUCKET}/database_url,SECRET_KEY=berglas://${BERGLAS_BUCKET}/secret_key,GS_BUCKET_NAME=berglas://${BERGLAS_BUCKET}/media_bucket \
    --add-cloudsql-instances $DATABASE_INSTANCE
```

*Note:* We are using the fully-qualified database instance name here. Although not strictly required, as our database is in the same project and region, it helps with clarity. 

Sadly, we have a few more steps. Even though we have deployed our service, **Django won't work yet**. Because: 

* We need to tell Django where to expect our service to run, and 
* we need to initalise our database.

#### Service URL, and `ALLOWED_HOSTS` 

We can either copy the URL from the output we got from the last step, or we can get it from `gcloud`

```shell,exclude
gcloud run services list
```

We could copy the URL from this output, or we can use [`--format` and `--filter`](https://dev.to/googlecloud/giving-format-to-your-gcloud-output-57gm) parameters:

```shell
export SERVICE_URL=$(gcloud run services list \
	--format="value(status.url)" \
	--filter="metadata.name=unicodex")
	 
echo $SERVICE_URL
```

Then, we can redeploy our service, updating *just* this new environment variable: 

```shell
gcloud run services update unicodex \
	--update-env-vars CURRENT_HOST=$SERVICE_URL
```

In this case, `CURRENT_HOST` is setup in our [setup.py](../setup.py) to be added to the `ALLOWED_HOSTS`, if defined. 


**Important**: `ALLOWED_HOSTS` takes a hostname without a scheme (i.e. without the leading 'https'). Our `settings.py` handles this by removing it, if it appears. 

#### Initialising Database

Our database currently has no schema or data, so we're going to have to do this, too. 

Back in our [local testing](00-test-local.md), we did this by executing `migrate`, `loaddata` and `automatesuperuser` from the command line. 

The problem is, we don't have a command-line. 

Well, we do, we have Cloud Shell, but that's not really *automatible*. We don't want to have to log into the console every time we have to run a migration. We *could*, and this is a valid option if your setup requires/demands it, but we're going to take the time now to automate migration and deployment. 

We're going to use [Cloud Build](https://cloud.google.com/cloud-build/), running manually for now, but automating it in the next step. We'll make it perform our database migrations, as well as build our image, and deploy our service. 

To start with, we need to give Cloud Build permission to access our database, and invoke Cloud Run. 

This code is similar to the `add-iam-policy-binding` code we used to [setup berglas](40-setup-secrets.md): 

```shell
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
export SA_CB_EMAIL=${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com

for role in cloudsql.client run.admin iam.serviceAccountUser; do
	gcloud projects add-iam-policy-binding ${PROJECT_ID} \
	--member serviceAccount:${SA_CB_EMAIL} \
	--role roles/${role}
done
```

You can check the current roles by:

* running `gcloud projects get-iam-policy $PROJECT_ID`, or 
* going to the [IAM & Admin](https://console.cloud.google.com/iam-admin/iam) page in the console. 

From here, we can then run our `gcloud builds submit` command again, but with new parameters: 

```shell
gcloud builds submit --config .cloudbuild/build-migrate-deploy.yaml \
    --substitutions="_REGION=${REGION},_DATABASE_INSTANCE=${DATABASE_INSTANCE},_SERVICE=unicodex,_BERGLAS_BUCKET=${BERGLAS_BUCKET}"
```

As suggested by the filename, this will perform three tasks for us: 

* Build the image (like we were doing before), 
* Apply the database migrations, and
* Deploy the service with the new image. 

But additionally: 

* it uses berglas to pull the secrets we stored earlier to create a local `.env` file
* using that `.env`, runs the django management commands: 
  * `./manage.py migrate`, which applies our database migrations
  * `./manage.py collectstatic`, which uploads our local static files to the media bucket
* it also, if there's no existing superuser, create a superuser. 


The full contents of the script is in [.cloudbuild/build-migrate-deploy.yaml](../.cloudbuild/build-migrate-deploy.yaml). 


Noted custom configurations: 

* We use `gcr.io/google-appengine/exec-wrapper` as an easier way to setup a Cloud SQL proxy. 
* We make own `.env` file using the ability for berglas to store a secret in a file (via `?destination`). This is because [Cloud Build envvars don't persist through steps](https://github.com/GoogleCloudPlatform/berglas/tree/master/examples/cloudbuild)
* We throw all our asks in one giant honking `.yaml`, because then we only need to call one `submit` command. 
* We also make assumptions about the secrets that we created earlier, so we only specify the bucket in which we are storing our secrets. 

We are also running this command with [substitutions](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values#using_user-defined_substitutions). These allow us to change the image, service, and database instance (which will be helpful later on when we define multiple environments). You can hardcode these yourself by commenting out the `substutitions:` stanza in the yaml file. 

---

And now. 

Finally. 

You can see the working website!

Go to the `SERVICE_URL` in your browser, and gaze upon all you created. 

You did it! 🏆

You can also log in with the `superuser`/`superpass`, and run the admin action as in [step 0](00-test-local.md). 

---

🤔 But what if all this didn't work? Check the [Debugging Steps](zz_debugging.md).


---

If this is as far as you want to take this project, think about [cleaning up](90-cleanup.md) your resources.

---

After all this work, each future deployment is exceedingly less complex. 

---

Next step: [Ongoing Deployments](60-ongoing-deployments.md)
