# 🐛🐛🐛 Debugging Steps 🐛🐛🐛 

*If at any point your deployment of unicodex breaks, hopefully one of the following debugging tricks can help.* ✨

## Enable `DEBUG` mode in Django

For security reasons, `DEBUG` should not be enabled in production. So, we didn't set it as enabled. 

To temporary enable it:

```
gcloud run services update unicodex --update-env-vars DEBUG=True
```

You should then reload the page, and see a more useful error. 

Remember to turn it off again!

```
gcloud run services update unicodex --update-env-vars DEBUG=False
```


## Database issues

### Check your instance settings

Is the instance you are connecting to correct?

For a number of configurations, the database instance needs to be in the form `PROJECT_ID:REGION:INSTANCE_NAME`. 

Check the instance name is correct by going to the [SQL Instances](https://console.cloud.google.com/sql/instances) listing and confirming your configuration matches the "instance connection name" listing for your instance. 

### Check your DATABASE_URL

Is your `DATABASE_URL` correct? Test it with `cloud_sql_proxy`!

Install the [`cloud_sql_proxy` client](https://cloud.google.com/sql/docs/postgres/sql-proxy#install) for your platform.  More instructions are in the [database](20-setup-sql.md) section. 

Then, we're going to test our `DATABASE_URL`. Well, some of it. 

In a new terminal:

```
./cloud_sql_proxy -instances=$PROJECT_ID:$REGION:$INSTANCE_NAME=tcp:5433
```

You should see "Ready for new connections".

What we've done is map our `DATABASE_INSTANCE` to localhost, port 5433. 

So, we need to remove the `//cloudsql/.../DATABASE` from our `DATABASE_URL`, and replace it with `localhost:5433`. 

So what was once: 

```
export DATABASE_URL=postgres://django:SECRET@//cloudsql/$PROJECT_ID:$REGION:$INSTANCE_NAME/$DATABASE_NAME
```

now becomes

```
export TEST_DATABASE_URL=postgres://django:SECRET@localhost:5433/$DATABASE_NAME
```

Then, in your original terminal: 

```
pip install psycopg2-binary
python -c "import os, psycopg2; conn = psycopg2.connect(os.environ['TEST_DATABASE_URL']);"
```

If this did not return an error, then it all worked!

*So what did we just do?*

We installed a pre-compiled PostgreSQL database adapter, [psycopg2-binary](https://pypi.org/project/psycopg2-binary/). 

We then started up the `cloud_sql_proxy` in a new tab, mapping that locally. 

Finally, we ran a tiny bit of Python that used the used the PostgreSQL adapter and created a connection using our new `TEST_DATABASE_URL` variable. 

---

## Still more database issues?

Check you have configured the correct IAM settings. 

Locate the [IAM permissions page](https://console.cloud.google.com/iam-admin/iam) in the Cloud Console, and confirm that the `unicodex service account` has Cloud SQL Client and Cloud Run admin roles. 

Locate the [Cloud Build settings page](https://console.cloud.google.com/cloud-build/settings/service-account) in the Cloud Console, and confirm that the `Cloud Run` GCP service is set to `ENABLED`.
---

Did you encounter a different problem? [Log an issue](https://github.com/GoogleCloudPlatform/django-demo-app-unicodex/issues).

---
