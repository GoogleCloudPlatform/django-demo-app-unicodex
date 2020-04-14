# First Deployment

*In this section, we'll create our first deployment.*

**We're nearly there!**

---

We're up to deploying our project for the first time!

This is going to be a bit complicated at first, but the work we do here will make every other deployment much simpler. 

You'll remember way back when we were [testing locally](00-test-local.md) we built two images: a `web` image and a `db` image. `db` will be replaced with the proper PostgreSQL database we've [already setup](20-setup-sql.md). So we just need to build the other image!

For that, we'll be using Cloud Build. This is a similar process to `docker build .`, but this will build the image on Google Cloud itself, and publish the image to the Google Cloud image repository, `gcr.io`. 

If you haven't already done so, you'll need a copy of this source code: 

```shell,exclude
git clone https://github.com/GoogleCloudPlatform/django-demo-app-unicodex
cd django-demo-app-unicodex
```

Then, we'll build the image:

```shell
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME .
```

Then, we can (finally!) create our Cloud Run service, telling it about the image we just created, the database we configured earlier, and the service account we set up. And just for good measure, we'll allow public access: 

```shell
gcloud run deploy $SERVICE_NAME \
  --allow-unauthenticated \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --add-cloudsql-instances $PROJECT_ID:$REGION:$INSTANCE_NAME \
  --service-account $CLOUDRUN_SA
```

*Note:* We are using the fully-qualified database instance name here. Although not strictly required, as our database is in the same project and region, it helps with clarity. 

Sadly, we have a few more steps. Even though we have deployed our service, **Django won't work yet**. You could try and navigate to the `unicodex-HASH-region.a.run.app` URL, but it will show an error. This is because: 

* We need to tell Django where to expect our service to run, and 
* we need to initialise our database.

#### Service URL, and `ALLOWED_HOSTS` 

Django has a setting called `ALLOWED_HOSTS`, which recommended to be defined for [security purposes](https://docs.djangoproject.com/en/3.0/ref/settings/#allowed-hosts). We want our set our `ALLOWED_HOSTS` to be the service URL of the site we just deployed. 

When we deployed our service, it told us the service URL that our site can be accessed from. We can either copy the URL from the output we got from the last step, or we can get it from `gcloud`

```shell,exclude
gcloud run services list
```

We could copy the URL from this output, or we can use a [`--format`](https://dev.to/googlecloud/giving-format-to-your-gcloud-output-57gm) parameter:

```shell
export SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --format "value(status.url)")
	 
echo $SERVICE_URL
```

Then, we can redeploy our service, updating *just* this new environment variable: 

```shell
gcloud run services update $SERVICE_NAME \
  --update-env-vars "CURRENT_HOST=${SERVICE_URL}"
```

In this case, `CURRENT_HOST` is setup in our [settings.py](../settings.py) to be added to the `ALLOWED_HOSTS`, if defined. 

**Important**: Django's `ALLOWED_HOSTS` takes a hostname without a scheme (i.e. without the leading 'https'). Our `settings.py` handles this by removing it, if it appears. 

#### Initialising Database

Our database currently has no schema or data, so we need to now set that up. 

Back in our [local testing](00-test-local.md), we did this by executing `migrate` and `loaddata` from the command line. 

The problem is, we don't have a command-line. 🤦‍♂️

Well, we do, we have Cloud Shell; but that's not really *automateable*. We don't want to have to log into the console every time we have to run a migration. Well, okay, we *could*, and this is absolutely a valid option if your setup requires/demands it, but for the scope of our application we're going to take the time now to automate migration during our deployment. 

We're going to use [Cloud Build](https://cloud.google.com/cloud-build/) and instead of just building the image like we did earlier, we'll make it perform build our image, apply our database migrations, and deploy our service; all at once. 

But to start, we need to give Cloud Build permission to do all these fancy things (like [deployment](https://cloud.google.com/run/docs/reference/iam/roles#additional-configuration): 

```shell
for role in cloudsql.client run.admin; do
  gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:${CLOUDBUILD_SA} \
    --role roles/${role}
done
```

We'll also need to ensure that for the final step in our deployment, Cloud Build has permission to deploy as Cloud Run. For that, we'll configure our Cloud Build to [act as our service account](https://cloud.google.com/run/docs/continuous-deployment-with-cloud-build#continuous-iam): 

```shell
gcloud iam service-accounts add-iam-policy-binding ${CLOUDRUN_SA} \
  --member "serviceAccount:${CLOUDBUILD_SA}" \
  --role "roles/iam.serviceAccountUser"
```

You can check the current roles by:

* running `gcloud projects get-iam-policy $PROJECT_ID`, or 
* going to the [IAM & Admin](https://console.cloud.google.com/iam-admin/iam) page in the console. 

From here, we can then run our `gcloud builds submit` command again, but this time specifying a configuration file: 

```shell
# migrate and deploy
gcloud builds submit \
  --config .cloudbuild/build-migrate-deploy.yaml \
  --substitutions "_REGION=${REGION},_INSTANCE_NAME=${INSTANCE_NAME},_SERVICE=${SERVICE_NAME}"
```

This command will take a few minutes to complete, but the output will show you what it's doing as it goes.

As suggested by the `--config` filename, this will perform three tasks for us: 

* Build the image (like we were doing before), 
* 'migrate', and 
* deploy the service with the new image. 

By 'migrate', we mean: 

* Configuring an environment using the secrets we setup earlier, to them 
* run the django management commands: 
  * `./manage.py migrate`, which applies our database migrations
  * `./manage.py collectstatic`, which uploads our local static files to the media bucket
* ⚠️  These commands need to be run at least once, but you can choose to remove this part of the script later (for instance, if you want to manually do database migrations).

The full contents of the script is in [.cloudbuild/build-migrate-deploy.yaml](../.cloudbuild/build-migrate-deploy.yaml). 


Noted custom configurations: 

* We use `gcr.io/google-appengine/exec-wrapper` as an easier way to setup a Cloud SQL proxy to interface with our database. 
* We use the Secret Manager client library to import specific secrets in our `settings.py`
* We are explicitly doing all these things as three steps in one configuration.

We are also running this command with [substitutions](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values#using_user-defined_substitutions). These allow us to change the image, service, and database instance (which will be helpful later on when we define multiple environments). You can hardcode these yourself by commenting out the `substitutions:` stanza in the yaml file. 

---

And now. 

Finally. 

You can see the working website!

Go to the `SERVICE_URL` in your browser, and gaze upon all you created. 

You did it! 🏆

You can also log in with the `superuser`/`superpass`, and run the admin action we did in [local testing](00-test-local.md). 

---

🤔 But what if all this didn't work? Check the [Debugging Steps](zz_debugging.md).

---

If this is as far as you want to take this project, think about [cleaning up](90-cleanup.md) your resources.

---

After all this work, each future deployment is exceedingly less complex. 

---

Next step: [Ongoing Deployments](60-ongoing-deployments.md)
