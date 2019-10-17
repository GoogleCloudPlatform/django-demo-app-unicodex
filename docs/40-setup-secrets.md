# Create some Berglas secrets

*In this section, we will setup some secrets!*

To encode our secrets, we'll be using [berglas](https://github.com/GoogleCloudPlatform/berglas).

----

> But why? 

It's a *stonkingly good idea* to ensure that only our application can access our database. To do that, we spent a whole lot of time setting up passwords. It's also a really good idea if only our application has access to these passwords. 

Plus, we'll be using `django-environ` later, which is directly influenced by [The Twelve Factor App](https://12factor.net/). You can read up how [Cloud Run complies with the Twelve Factor application](https://cloud.google.com/blog/products/serverless/a-dozen-reasons-why-cloud-run-complies-with-the-twelve-factor-app-methodology).

This setup looks a bit long, but application security security is no joke, and this is an important part of our app to setup. 

---

To setup berglas, follow its [setup documentation](https://github.com/GoogleCloudPlatform/berglas#setup). 

You'll end up running a command like: 

```shell
export BERGLAS_BUCKET=${PROJECT_ID}-secrets

berglas bootstrap --project $PROJECT_ID --bucket $BERGLAS_BUCKET
```

Specific things to note: 

* We already have our `PROJECT_ID`.
* The `BERGLAS_BUCKET` is **NOT** `${PROJECT_ID}-media` from earlier. We suggest using something like `${PROJECT_ID}-secrets`. This bucket should not yet exist: berglas will create it for us. 
* Berglas will suggest enabling a bunch of services, but we did that already. Re-enabling won't affect our setup. 

You should now be able to check that berglas works, and doesn't see any active secrets: 

```shell,exclude
berglas --version
berglas list ${PROJECT_ID}-secrets
```

From here, we need to create a number of secrets. 

Two of these need to be random strings. You can generate a string like so: 

```shell,exlucde
python -c "import secrets; print(secrets.token_urlsafe(50))"
```

This is a [Python standard library method](https://docs.python.org/3/library/secrets.html#secrets.token_urlsafe) that will generate a 50 byte string for us. This will be around ~65 characters, which is plenty for our purposes.

The secrets we need to create: 

 * `database_url`, with the value `DATABASE_URL`, as mentioned earlier in the Database section
 * `secret_key`, a mininum 50 character random string, for django's `SECRET_KEY`
 * `media_bucket`, the media bucket we created earlier (`${PROJECT_ID}-media`)

And for the django admin (`/admin`), we'll need our superuser: 

 * `superuser`, a superuser name (`admin`? your name?)
 * `superpass`, a secret password, using our generator from earlier. 

 
Also, for each of these secrets, we need to define *who* can access them. Berglas allows us to define exactly which parts of Google Cloud is allowed to use our secrets. Nifty!

In our case, we want only Cloud Run and Cloud Build (for [automating deployments](60-ongoing-deployment.md) later) to be able to view our secrets. In order to do that, we need to get their service account names. 

We can programaically collect the information we need for this, and setup some of the policy binding we need, by running the following:

```shell
export KMS_KEY=projects/${PROJECT_ID}/locations/global/keyRings/berglas/cryptoKeys/berglas-key
export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format 'value(projectNumber)')
export SA_EMAIL=${PROJECT_NUMBER}-compute@developer.gserviceaccount.com
export SA_CB_EMAIL=${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com

gcloud projects add-iam-policy-binding ${PROJECT_ID} --member serviceAccount:${SA_EMAIL} --role roles/run.viewer
```

<small>Tip: The vaues used for the `KMS_KEY` assumes you used the default value from the Berglas setup.</small>

Now, we can create our secrets. 

For **each** `SECRET` and `VALUE`:

```shell,exclude
# sample code
berglas create ${BERGLAS_BUCKET}/$SECRET $VALUE --key ${KMS_KEY}
berglas grant ${BERGLAS_BUCKET}/$SECRET --member serviceAccount:${SA_EMAIL}
berglas grant ${BERGLAS_BUCKET}/$SECRET --member serviceAccount:${SA_CB_EMAIL}
```

These three commands will: 

 * create the secret
 * allow the Cloud Run service access the secret
 * allow the Cloud **Build** service access the secret. 

So you'll end up running: 

```shell
export SUPERPASS=$(python -c "import secrets; print(secrets.token_urlsafe(50))")
export SECRET_KEY=$(python -c "import secrets; print(secrets.token_urlsafe(50))")

berglas create ${BERGLAS_BUCKET}/database_url $DATABASE_URL  --key ${KMS_KEY}
berglas create ${BERGLAS_BUCKET}/media_bucket $MEDIA_BUCKET  --key ${KMS_KEY}
berglas create ${BERGLAS_BUCKET}/superuser    admin          --key ${KMS_KEY}
berglas create ${BERGLAS_BUCKET}/superpass    $SUPERPASS     --key ${KMS_KEY}
berglas create ${BERGLAS_BUCKET}/secret_key   $SECRET_KEY    --key ${KMS_KEY}

for SECRET in $(berglas list ${BERGLAS_BUCKET}); do
	berglas grant ${BERGLAS_BUCKET}/$SECRET --member serviceAccount:${SA_EMAIL}
	berglas grant ${BERGLAS_BUCKET}/$SECRET --member serviceAccount:${SA_CB_EMAIL}
done

```

You can confirm you're ready for the next step by listing the secrets in the bucklet: 

```shell
berglas list $BERGLAS_BUCKET
```

The output for this should be: 

```exclude
database_url
media_bucket
secret_key
superpass
superuser
```
 
If you *need* to get the **value** of these secrets, you can run: 

```shell,exclude
berglas access ${BERGLAS_BUCKET}/$SECRET
```

Note that the secret values will not have a new-line character at the end, so they'll look a little funny in your terminal. They're machine-readable, though!

---

You now have all the secrets you need to deploy django securely! 🤫

---

Next step: [First Deployment](50-first-deployment.md)