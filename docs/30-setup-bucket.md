# Create a Cloud Storage Bucket 

*In this section we will be creating a place to store our media assets.*

---

We need to create a new bucket to store our media assets (django admin assets, design images, etc). 

Bucket names are **globally unique** across all of Google Cloud, so consider the scope of the bucket when you create it. 

We suggest that you name it something unique to the project, but still noting it's purpose. Here's what we suggest:

```shell
export GS_BUCKET_NAME=${PROJECT_ID}-media
```

Now, create our bucket using the [Google Storage utility](https://cloud.google.com/storage/docs/gsutil) `gsutil` (which was installed for you when you installed `gcloud`): 

```shell
gsutil mb -l ${REGION} gs://${GS_BUCKET_NAME}
```

We'll also need to give our service account permission to operate on this bucket (which it needs to do Django admin action based [storage object alteration](https://cloud.google.com/storage/docs/access-control/using-iam-permissions#bucket-add): 

```shell
gsutil iam ch \
  serviceAccount:${CLOUDRUN_SA}:roles/storage.objectAdmin \
  gs://${GS_BUCKET_NAME} 
```

---

We now have somewhere to store our media! 🖼

---

Next step: [Create some secrets](40-setup-secrets.md)
