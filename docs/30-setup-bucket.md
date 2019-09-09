# Create a Cloud Storage Bucket 

*In this section we will be creating a place to store our media assets.*

Given the setup in the [Setup Google Cloud Platform environment](10-setup-gcp.md) section, this part is faily painless. 

We need to create a new bucket to store our media assets. This won't be the last bucket we'll create, so a suggested name is: `${PROJECT_ID}-media`.

```shell
gsutil mb gs://${PROJECT_ID}-media
```

We now have somewhere to store our media! 🖼

---

Next step: [Create some Berglas secrets](40-setup-secrets.md)