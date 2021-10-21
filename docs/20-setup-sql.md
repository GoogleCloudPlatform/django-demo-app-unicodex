# Create a Cloud SQL Instance

*In this section we will be creating a database instance, database, and user, and come away with our `DATABASE_URL`*

To store our application data, we'll need to setup a [Cloud SQL](https://console.cloud.google.com/sql/instances) instance, and a specific database with a database user.

---

**This section is one of the more complex parts of this tutorial.** But it's worth going to the effort.

---

It's a *really very good idea* to setup our database in a way that's going to be secure. You *could* run just the basic `gcloud sql` commands here to create an instance and user, but using these commands gives the user [too many permissions](https://cloud.google.com/sql/docs/postgres/users#default-users). 

The Cloud SQL API is designed to give the same functionality to multiple different database implementations: (for the most part) the same commands will create databases and users in Postgres, MySQL, or infact MSSQL instances. Since these databases are so different, there's no(t yet an) implementation for explicitly setting Postgres roles, so we have no option to set this in the API (which is used by both `gcloud` and the web Cloud Console.)

This is why we're taking the time to set things up explicitly. We'll create our instance and database, then take the time to create a low-access user that Django will use to login to the database. 

---

### A note on generating passwords

There are a number of secret strings for passwords and such that we will be generating in this tutorial. Ensuring a unique and complex password is paramount for security. 

For many of our examples, we'll be using this sequence to generate a random string: 

```shell,exlucde
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
```

Breaking this command down, it uses input from [urandom](https://www.2uo.de/myths-about-urandom/), deletes any non letter or number values, gives us this value in 64-character length chunks, and gives us the first line in that output. As a mess of characters that is probably never going to ever return us the same value, this is good enough for our purposes (and many other purposes. The discussion about true randomness and the entire field of cryptography is outside the scope of this tutorial.)

There are other ways you can generate random strings, for example with pure python: 

```shell,exclude
python -c "import secrets; print(secrets.token_urlsafe(50))"
```

This is a [Python standard library method](https://docs.python.org/3/library/secrets.html#secrets.token_urlsafe) that will generate a 50 byte string for us, or around ~65 characters. Plenty long enough for a password.

For our purposes, we'll stick to the `/dev/urandom` method. 

---

### Database Instance

The database instance creation process has many configuration options, as detailed by the [Create a Cloud SQL instance](https://cloud.google.com/sql/docs/postgres/quickstart#create-instance) section of the "Quickstart for Cloud SQL for PostgreSQL" tutorial.

Some important notes: 

* The default configurations may work for you, but be sure to check if there's anything you want to change.
  * For instance, we've chosen a non-minimum instance size. [Learn more about Instance Settings](https://cloud.google.com/sql/docs/postgres/instance-settings).
* Make sure you make note of the "Default User Password". We'll refer to this as `ROOT_PASSWORD`.
* The instance creation will take **several minutes**. Do not worry. 

A sample version of what you'd end up running, if you chose the defaults (the latest Postgres version with the smallest instance size), and generating a random password, would be the following: 

```shell
export INSTANCE_NAME=YourInstanceName 
export ROOT_PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

gcloud sql instances create $INSTANCE_NAME \
  --database-version POSTGRES_13 --cpu 2 --memory 4GB \
  --region $REGION \
  --project $PROJECT_ID \
  --root-password $ROOT_PASSWORD
```

We can confirm we've correctly setup this database for our project by checking for it in `gcloud`: 

```shell,exclude
gcloud sql instances list
```

Google Cloud often refers to "fully-qualified" identifier to specify our database instance, which is a a combination of our project ID, region, and the instance name itself. We can set this variable now to use it later on. 

```shell
export DATABASE_INSTANCE=$PROJECT_ID:$REGION:$INSTANCE_NAME
```

This is an great time to make note about disambiguation: We will talk about databases within database instances a lot, but when we use the three-segmented version, we are talking about the Cloud SQL managed database instance. 

### Our Database 

Our database **instance** can hold many **databases**. For our purposes, we're going to setup a `unicodex` database: 

```shell
export DATABASE_NAME=unicodex
gcloud sql databases create $DATABASE_NAME \
  --instance=$INSTANCE_NAME
```

### A user that can access only our database. 

Finally, our user. This is where it gets complex. 

Since by default [users created using Cloud SQL have the privileges associated with the `cloudsqlsuperuser` role](https://cloud.google.com/sql/docs/postgres/create-manage-users#creating), we don't want our django user to have such permissions. So, we'll have to manually create our user. 

To do this, we can connect directly to our new instance from the command line: 

```shell,exclude
gcloud sql connect $INSTANCE_NAME
```

There will be a bit of output here. This is generated by [Cloud SQL Proxy](https://cloud.google.com/sql/docs/postgres/sql-proxy), which `gcloud` is using behind the scenes. 

But, you will be prompted for the DBPASSWORD for `SQL user [postgres]`. This is the `ROOT_PASSWORD` we set earlier. 

Once successfully connected, you'll be dropped into a postgres console. It will look something like this: 

```shell,exclude
psql (11.5)
Type "help" for help.

unicodex=>
```

From here, the commands we need to execute are: creating our user, and giving it access to only our specific database:

```sql,exclude
CREATE USER "<DBUSERNAME>" WITH PASSWORD "<DBPASSWORD>"; 
GRANT ALL PRIVILEGES ON DATABASE "<DATABASE_NAME>" TO "<DBUSERNAME>";
```

Some notes: 

* environment variables won't explicitly work here. All the terms in `"<DOUBLE-QUOTES>"` will need to be replaced manually. 
* Our `django` user needs `CREATE` and `ALTER` permissions to perform database migrations. It only needs these permissions on the database we created, not any other database in our instance. Hence, we're being explicit. 

----

You **could** create the user using just the `gcloud` command yourself, but there are some limitations to this method: 
 
 * The `gcloud` command does not handle custom roles, and your default role will be `cloudsqladmin`, which is tremendously high for a Django database user. 
 * You will have to manually go and change the role yourself after. 

```shell
export DBUSERNAME=unicodex-django
export DBPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 40 | head -n 1)

gcloud sql users create $DBUSERNAME \
  --password $DBPASSWORD \
  --instance $INSTANCE_NAME
```

---

### Configuring our Database URL

We now have all the elements we need to create our `DATABASE_URL`. It's a connection URL, a configuration format shared by many systems including [`django-environ`](https://django-environ.readthedocs.io/en/latest/). 

This string is **super secret**, so it's one of the secrets we'll be encrypting.

To create the DATABASE_URL, we'll need the `DBUSERNAME` and `DBPASSWORD` for the `DATABASE_NAME` on the `INSTANCE_NAME` we created, in whatever `REGION` to form the `DATABASE_URL`:

```shell
export DATABASE_URL=postgres://$DBUSERNAME:${DBPASSWORD}@//cloudsql/$PROJECT_ID:$REGION:$INSTANCE_NAME/$DATABASE_NAME
```

We now have the environment variables we need! 🍪

---

🤔 Want to check your `DATABASE_URL`? You can use the "Database issues" section in the [debugging docs](zz_debugging.md)
 
---

Next step: [Create a Cloud Storage Bucket](30-setup-bucket.md)
