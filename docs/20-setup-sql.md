# Create a Cloud SQL Instance

*In this section we will be creating a database instance, database, and user, and come away with our `DATABASE_URL`*

To store our application data, we'll need to setup a [Cloud SQL](https://console.cloud.google.com/sql/instances) instance, and a specific database with a database user.

---

**This section is one of the more complex parts of this tutorial.** But it's worth going to the effort.

---

It's a *really very good idea* to setup our database in a way that's going to be secure. You *could* run just the basic `gcloud sql` commands here to create an instance and user, but using these commands gives the user [too many permissions](https://cloud.google.com/sql/docs/postgres/users#default-users).

This is why we're taking the time to set things up explicitly. 

---

### Database Instance

The database instance creation process has many configuration options, as detailed by the [Create a Cloud SQL instance](https://cloud.google.com/sql/docs/postgres/quickstart#create-instance) section of the "Quickstart for Cloud SQL for PostgreSQL" tutorial.

Important notes: 

* The default configurations may work for you, but be sure to check if there's anything you want to change.
* Make sure you make note of the "Default User Password". We'll refer to this as `MASTER_PASSWORD`.
* The instance creation may take **several minutes.** 

We can confirm we've correctly setup this database for our project by checking for it in `gcloud`: 

```shell,exclude
gcloud sql instances list
```

Make note of the "NAME", which we will call `INSTANCE_NAME`, to avoid confusion later. We will also use the "LOCATION" later as our `REGION`.

```shell,exclude
export INSTANCE_NAME=YourInstanceName
export REGION=us-central1 # probably
```

You can programmatically get the region for your instance by running a `filter/format` command: 

```shell,exclude
gcloud sql instances list --format 'value(region)' --filter name=$INSTANCE_NAME
```

### Our Database 

Our database **instance** can hold many **databases**. For our purposes, we're going to setup a `unicodex` database: 

```shell,exclude
gcloud sql databases create unicodex --instance=$INSTANCE_NAME
```

And then, the user for this database. 


Since by default [users created using Cloud SQL have the privileges associated with the `cloudsqlsuperuser` role](https://cloud.google.com/sql/docs/postgres/create-manage-users#creating), and we don't want our django user to have such permissions, we'll have to move to the Cloud Shell for the next part. 

Choose your own adventure!

* Option A: [Use Cloud Shell](#cloud-shell) to interact with the database in the browser
* Option B: [Setup `cloud_sql_proxy`](#cloud-sql-proxy) and interact with the database on the command line. 

---

#### Cloud Shell

Go to the [Cloud SQL Console](https://console.cloud.google.com/sql/instances) and select the instance you just created. 

Click on 'Connect using Cloud Shell', and you'll be provisioned a Cloud Shell machine, and a tab at the bottom of your browser will show the console. 

It should also pre-populate with the command you need: 

```shell,exclude
☁️ gcloud sql connect $INSTANCE_NAME --user=postgres --quiet
```

You'll be asked for your `MASTER_PASSWORD` that we set earlier. 

We will then be within the **postgres** terminal. This is yet another terminal. We won't be here too long. 

But now, it's time to jump to [Creating our database user](#creating-our-database-user) and joining our friends from the Cloud SQL Proxy branch. 

---

#### Cloud SQL Proxy

If you chose to, we can stay in the console and configure our database user directly. This is going to require the use of [Cloud SQL Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy). This proxy allows us to establish a temporary authenticated tunnel into our database to perform management commands. 

You'll need to [install](https://cloud.google.com/sql/docs/postgres/sql-proxy#install) the proxy for your system to get started. 

📌 I suggest making sure your proxy is placed somewhere in your `$PATH` so you can invoke it using `cloud_sql_proxy` from anywhere in your terminal. And also, if you install it outside of your current working project, you won't accidentally commit it to your git repo. 

Once you have the proxy installed, we need to setup a tunnel to our database. In a new terminal:

```shell,exclude
cloud_sql_proxy -instances=$PROJECT_ID:$REGION:$DATABASE_INSTANCE=tcp:5432
```


📌 If you get an error about `bind: address already in use`, just use `5433` or similar. And remember to use this new port in the next command ✨

Then, we can connect to our database: 

```shell,exclude
psql -U postgres --port 5432 --host localhost
```

Continue straight into creating your database user!

---

### Creating our database user

The commands we need to execute are creating our user, and giving it access to only our specific database. The form of the command is:

```sql,exclude
CREATE USER username WITH PASSWORD password; 
GRANT ALL PRIVILEGES ON DATABASE database TO username;"
```

Some notes: 

* environment variables won't explicitly work here; they are being used as placeholders.
* Our django user needs `CREATE` and `ALTER` permissions to perform database migrations. It only needs these permissions on the database we created, not any other database in our instance. 

----

📝 You could execute all the steps in this section up to now non-interactively. You should have an understanding of what these commands are executing before starting. 

```shell
export INSTANCE_NAME=YourInstanceName 
export REGION=us-central1
export DATABASE_NAME=unicodex

export PGPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

if $(gcloud sql instances describe $INSTANCE_NAME --project=$PROJECT_ID); then
  echo "instance exists, skipping"
else
  gcloud sql instances create $INSTANCE_NAME \
    --database-version=POSTGRES_11 \
    --tier=db-f1-micro  \
    --region=$REGION \
    --project=$PROJECT_ID \
    --root-password=$PGPASSWORD
fi
	 
export DATABASE_INSTANCE=$PROJECT_ID:$REGION:$INSTANCE_NAME

export USERNAME=django
export PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1)

if $(gcloud sql databases describe $DATABASE_NAME --instance=$INSTANCE_NAME); then
    echo "database exists, skipping"
else
    gcloud sql databases create $DATABASE_NAME --instance=$INSTANCE_NAME
fi

cloud_sql_proxy -instances=$DATABASE_INSTANCE=tcp:5435 &
sleep 5

psql -U postgres --port 5435 --host localhost -c "CREATE USER \"$USERNAME\" WITH PASSWORD '${PASSWORD}'; GRANT ALL PRIVILEGES ON DATABASE \"$DATABASE_NAME\" TO \"$USERNAME\";"
```


---

### Configuring our Database URL

We now have all the elements we need to create our `DATABASE_URL`. This is a format defined in a lot of systems, including [`django-environ`](https://django-environ.readthedocs.io/en/latest/). 

Back in our **local terminal** (hello old friend!), we will need the `USERNAME` and `PASSWORD` for the `DATABASE_NAME` on the `INSTANCE_NAME` we created, in whatever `REGION` to form the `DATABASE_URL`:

```shell,exclude
# use the values from your previous commands
export USERNAME=django
export PASSWORD=secret_password
export DATABASE_NAME=unicodex
```

Then, we can create our `DATABASE_URL`:

```shell
export DATABASE_URL=postgres://$USERNAME:${PASSWORD}@//cloudsql/$PROJECT_ID:$REGION:$INSTANCE_NAME/$DATABASE_NAME
```

For convenience, later we will also need a smaller version of this string, which just our absolute Cloud SQL Instance identifer: 

```shell,exclude
export DATABASE_INSTANCE=$PROJECT_ID:$REGION:$INSTANCE_NAME
```

We now have the environment variables we need! 🍪

---

🤔 Want to check your `DATABASE_URL`? You can use the "Database issues" section in the [debugging docs](zz_debugging.md)
 
---

Next step: [Create a Cloud Storage Bucket](30-setup-bucket.md)