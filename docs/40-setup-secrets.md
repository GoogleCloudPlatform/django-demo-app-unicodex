# Create some Secrets

*In this section, we will setup some secrets!*

To encode our secrets, we'll be using [Secrets Manager](https://cloud.google.com/secret-manager/docs)

----

> But why? 

It's a *exceedingly good idea* to ensure that only our application can access our database. To do that, we spent a whole lot of time setting up passwords. It's also a really good idea if only our application has access to these passwords. 

Plus, we'll be using `django-environ` later, which is directly influenced by [The Twelve Factor App](https://12factor.net/). You can read up how [Cloud Run complies with the Twelve Factor application](https://cloud.google.com/blog/products/serverless/a-dozen-reasons-why-cloud-run-complies-with-the-twelve-factor-app-methodology).

This setup looks a bit long, but application security security is no joke, and this is an important part of our app to setup. 

---

Back in [an earlier step](docs/10-setup-gcp.md) we enabled the Secret Manager API, so we now have access to use it. So now, we can create our secrets. 

There are five secrets we need to create. 

Three are our base django secrets: 

 * `DATABASE_URL`, with the value `DATABASE_URL`, as [mentioned earlier](20-setup-sql.md),
 * `SECRET_KEY`, a minimum 50 character random string for django's `SECRET_KEY`,
 * `GS_BUCKET_KEY`, the media bucket we [created earlier](30-setup-media.md).
 
We'll also need an additional two for our django admin login (`/admin`):

 * `SUPERUSER`, a superuser name (`admin`? your name?)
 * `SUPERPASS`, a secret password, using our generator from earlier. 

Also, for each of these secrets, we need to define *who* can access them. 

In our case, we want only Cloud Run and Cloud Build (for [automating deployments](60-ongoing-deployment.md) later) to be able to view our secrets. In order to do that, we need to get their service account names. 

We know our Cloud Run service account, because we explicitly created it earlier. So we just need our Cloud Build account. It was automatically created for us when we enabled the Cloud Build API, and is identified by an email address that uses our project number (rather than the project ID we've been using so far): 

```shell
export PROJECTNUM=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
export CLOUDBUILD_SA=${PROJECTNUM}@cloudbuild.gserviceaccount.com
```

---

We can reduce the number of the secrets that need to stored by introducing some minor complexity: django-environ accepts a `.env` file of `key=value` pairs. We can create a file of settings that Django will always require: the databse connection string, media bucket, and secret key. The admin username and password can stay seperate, and have reduced access.  

Create a .env file, with the values defined earlier 

```shell
echo DATABASE_URL=\"${DATABASE_URL}\" > .env
echo GS_BUCKET_NAME=\"${GS_BUCKET_NAME}\" >> .env
echo SECRET_KEY=\"$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 50 | head -n 1)\" >> .env
```

Then, create the secret and assign the services access:

```shell
gcloud secrets create django_settings --replication-policy automatic --data-file .env

gcloud secrets add-iam-policy-binding django_settings \
  --member serviceAccount:$CLOUDRUN_SA \
  --role roles/secretmanager.secretAccessor
  
  gcloud secrets add-iam-policy-binding django_settings \
  --member serviceAccount:$CLOUDBUILD_SA \
  --role roles/secretmanager.secretAccessor
```

These commands will: 

 * create the secret, with the intial version being the secret from file, and
 * allow our service account to access the secret. 

As for the admin username and password secrets, they should only be accessed by Cloud Build: 

```shell
export SUPERUSER="admin"
export SUPERPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)

for SECRET in SUPERUSER SUPERPASS; do
  gcloud secrets create $SECRET --replication-policy automatic
    
  echo -n "${!SECRET}" | gcloud secrets versions add $SECRET --data-file=-
    
  gcloud secrets add-iam-policy-binding $SECRET \
    --member serviceAccount:$CLOUDBUILD_SA \
    --role roles/secretmanager.secretAccessor
done 
```

Some of the bash tricks we're using here: 

* Many of the commands are very similar, so we're using `for` loops a lot.
* The `${!var}` expands the value of `var`, which allows us to dynamically define variables. This works in bash, but may not work in other shells. Running all these scripts in bash is a good idea, just in case the eccentric doesn't work in your shell. 
* The `-n` in `echo` makes sure we don't accidentally save any trailing newline characters to our secret.
* You can call `secrets create` with a `--data-file` once, or you can use `secrets create`/`secrets versions add`. When you need to update a secret, just repeat `secrets versions add`.

---
 
If you *need* to get the **value** of these secrets, you can run the following: 

```shell,exclude
gcloud secrets versions access latest --secret $SECRET
```

---

You now have all the secrets you need to deploy django securely! 🤫

---

Next step: [First Deployment](50-first-deployment.md)
