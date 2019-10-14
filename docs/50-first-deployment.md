# First Deployment

*In this section, we'll create our first deployment*

**We're nearly there!**

We're up to deploying our project for the first time!

This is a little bit complicated the first time, but it'll be much easier for every other deployment. 

You'll remember way back at the [first step](00-test-local.md), we built two images: a `web` image and a `db` image. 

`db` will be replaced with the proper postgres database we've [already setup](20-setup-sql.md). 

So we just need to build the other image!

For that, we'll be using Cloud Build. This is a similar process to `docker build .`, but this will build the image on Google Cloud itself, and publish the image to the Google Cloud image repository, `gcr.io`. 

To build the image:

```shell
gcloud builds submit --tag gcr.io/$PROJECT_ID/unicodex .
```

Then, we can (finally!) create our Cloud Run service using this image. We'll also tell it all about the database we setup earlier, and all those secrets: 

```
gcloud beta run deploy unicodex \
    --allow-unauthenticated \
    --region us-central1 \
    --image gcr.io/$PROJECT_ID/unicodex \
    --update-env-vars DATABASE_URL=berglas://${BERGLAS_BUCKET}/database_url,SECRET_KEY=berglas://${BERGLAS_BUCKET}/secret_key,GS_BUCKET_NAME=berglas://${BERGLAS_BUCKET}/media_bucket \
    --add-cloudsql-instances $DATABASE_INSTANCE
```

*Note:* Cloud Run is still in beta at the time of writing. There may be additional options you have to set here. Best bet is to choose the default that is offered. 

We have *one more step*. 

Even though we have deployed our service, **Django won't work yet**. 

This is because Django also wants to know what host we will be serving at, and we don't know what URL we'll get ahead of time. 

But now we've deployed, so we can check our new URL, and update our service with this new environment variable. 

We can either copy the URL from the output we got from the last step, or we can get it from `gcloud`

```
gcloud beta run services list
```

We could copy the URL from this output, or we can use [`--format` and `--filter`](https://dev.to/googlecloud/giving-format-to-your-gcloud-output-57gm) parameters:

```shell
export SERVICE_URL=$(gcloud beta run services list \
	--format="value(status.url)" \
	--filter="metadata.name=unicodex") 
	
echo $SERVICE_URL
```

Then, we can redeploy our service, updating *just* this new environment variable: 

```
gcloud beta run services update unicodex \
	--update-env-vars CURRENT_HOST=$SERVICE_URL
```

In this case, `CURRENT_HOST` is setup in our [setup.py](../setup.py) to be added to the `ALLOWED_HOSTS`, if defined. 


**Important**: `ALLOWED_HOSTS` takes a hostname without a scheme (i.e. without the leading 'https'). Our `settings.py` handles this by removing it, if it appears. 

#### Initialising Database



---

And now. 

Finally. 

You can see the working website!

Go to the `SERVICE_URL` in your browser, and gaze upon all you created. 

You did it! 🏆

---

🤔 But what if it didn't work? Check the [Debugging Steps](zz_debugging.md).


---

After all this work, each future deployment is exceedindly less complex. 

---

Next step: [Ongoing Deployments](docs/60-ongoing-deployment.md)