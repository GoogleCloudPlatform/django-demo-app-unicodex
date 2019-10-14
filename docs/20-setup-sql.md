# Create a Cloud SQL Instance

*In this section we will be creating a database instance, database, and user, and come away with our `DATABASE_URL`*

To store our application data, we'll need to setup a postgres [Cloud SQL](https://console.cloud.google.com/sql/instances) instance, and a specific database with a database user.

This part of the tutorial is a bit longer, so we'll have section headers :)

### Database Instance

The database instance creation process has many configuration options, but a lot of good defaults, so we're going to follow the [Create a Cloud SQL instance](https://cloud.google.com/sql/docs/postgres/quickstart#create-instance) section of the "Quickstart for Cloud SQL for PostgreSQL" tutorial (rather than running a CLI command.)

Important notes: 

* The default configurations may work for you, but be sure to check if there's anything you want to change.
* Make sure you make note of the "Default User Password". We'll refer to this as `MASTER_PASSWORD`.
* The instance creation may take **several minutes.** 

We can confirm we've correctly setup this database for our project by checking for it in `gcloud`: 

```
gcloud sql instances list
```

Make note of the "NAME", which we will call `INSTANCE_NAME`, to avoid confusion later. We will also use the "LOCATION" later as our `REGION`.

```
export INSTANCE_NAME=YourinstanceName
export REGION=us-central1 # probably. 
```
Note, the region we need may be listed as, for example, "us-central1-a", but we don't require the zone ("a"). 

### Our Database 

Our database **instance** can hold many **databases**. For our purposes, we're going to setup a `unicodex` database: 

```
gcloud sql databases create unicodex --instance=$INSTANCE_NAME
```

And then, the user for this database. 

Since by default [users created using Cloud SQL have the privileges associated with the `cloudsqlsuperuser` role](https://cloud.google.com/sql/docs/postgres/create-manage-users#creating), and we don't want our django user to have such permissions, we'll have to move to the Cloud Shell for the next part. 

---

**A note on Cloud Shell**

To help with the ease of setting up our databases, we'll be moving away form our local terminal and using the [Cloud Shell](https://cloud.google.com/shell/docs/quickstart) for part of this tutorial. Cloud Shell is an environment to help us work with managing resources hosted on Google Cloud. 

We *could* run the entire tutorial locally, that would require setting up  the [Cloud SQL Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy), and other configurations. Since we don't need to be here for long, we'll use the Cloud Shell. 

To help, we've prefixed all the Cloud Shell commands in this section with "☁️" to remind you this is for Cloud Shell.

---

Go to the [Cloud SQL Console](https://console.cloud.google.com/sql/instances) and select the instance you just created. 

Click on 'Connect using Cloud Shell', and you'll be provisioned a Cloud Shell machine, and a tab at the bottom of your browser will show the console. 

It should also pre-populate with the command you need: 

```
☁️ gcloud sql connect $INSTANCE_NAME --user=postgres --quiet
```

You'll be asked for your `MASTER_PASSWORD` that we set earlier. 

We will then be within the **postgres** terminal. This is yet another terminal. We won't be too long. 

We can then create our django user: 

```
CREATE USER django WITH PASSWORD 'secret_password';
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO django;
```
In this case, we are using the `USERNAME` "django" and the `PASSWORD` "secret_password". Of course, you will **use a much more secure password**.

We can now exit the postgres terminal, and leave the Cloud Shell. 

---

We now have all the elements we need to create our `DATABASE_URL`. This is a format defined in a lot of systems, including [`django-environ`](https://django-environ.readthedocs.io/en/latest/). 

Back in our **local terminal** (hello old friend!), we will need the `USERNAME` and `PASSWORD` for the `DATABASE_NAME` on the `INSTANCE_NAME` we created, in whatever `REGION` to form the `DATABASE_URL`:

```shell
export USERNAME=django
export PASSWORD=secret_password
export DATABASE_NAME=unicodex

export DATABASE_URL=postgres://$USERNAME:${PASSWORD}@//cloudsql/$PROJECT_ID:$REGION:$INSTANCE_NAME/$DATABASE_NAME
```

For convenience, later we will also need a smaller version of this string, which just our absolute Cloud SQL Instance identifer: 

```shell
export DATABASE_INSTANCE=$PROJECT_ID:$REGION:$INSTANCE_NAME
```

We now have the environment variables we need! 🍪

---

🤔 Want to check your `DATABASE_URL`? You can use the "Database issues" section in the [debugging docs](zz_debugging.md)
 
---

Next step: [Create a Cloud Storage Bucket](30-setup-bucket.md)