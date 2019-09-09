
# Ongoing Deployments

TODO(glasnt): Incomplete and untested.

We did so much setup. 

We configured so many things. 

But we haven't actually added any data yet. 

And we need to do a few more things to get that to happen.

---

This section makes the following assumptions that may be controversial: 

* We want to migrate data and assets every time we deploy.
* We want to make use of shell scripts to reduce the complexity of our Cloud Build configuration.
* We are okay with this. 

---

Because we're working in Cloud Run we don't have access to a console that we can run our `./manage.py migrate` commands against. 

We could spend a bunch of time to set this up locally just to do this once, but instead, let's automate the process. 

The configurations have been already placed in `cloudbuild.yaml` for you. To run this: 

```
gcloud builds submit --config .cloudbuild/cloudbuild.yaml
```

This file does we manually did the [last step](50-first-deployment.md): 

* build the unicodex image
* deploy the image to Cloud Run

But additionally: 

* uses Berglas to pull the secrets we stored earlier to create a local `.env` file
* using that `.env`, runs the django management commands: 
  * `./manage.py migrate`, which applies our database migrations
  * `./manage.py collectstatic`, which uploads our local static files to the media bucket
* it also, if there's no existing superuser, create a superuser. 

You can check the contents of [.cloudbuild.yaml](../.cloudbuild/cloudbuild.yaml) to see exactly what's going on. 

Hacks: 

* We use `gcr.io/google-appengine/exec-wrapper` as an easier way to setup an Cloud SQL proxy. 
* We make own `.env` file using the ability for berglas to store a secret in a file (via `?destination`). This is because Cloud Build envvars don't persist through steps
* We throw all our asks in one giant honking `cloudbuild.yaml`, because it makes this easier. 


---

In the next step, we'll setup this automation to run every time we merge our code to master. 

---

Next step: [Setup Cloud Build trigger](70-setup-trigger.md)

