# Create a Cloud Storage Bucket 

*In this section we will be creating a place to store our media assets.*

Compared to the complexity of the [last section](20-setup-sql.md) section, this part is fairly painless. 😂

We need to create a new bucket to store our media assets (django admin access, design images, etc). This won't be the last bucket we'll create, so a suggested name is `${PROJECT_ID}-media`.

```shell
gsutil mb gs://${PROJECT_ID}-media
```

---

We now have somewhere to store our media! 🖼

---

Next step: [Create some Berglas secrets](40-setup-secrets.md)