# Manual Deployments

*In this section, we'll discuss manual deployment strategies.*

While deployments are automatable, there may be times where automatically deploying when a pull request happens might not be adventageous: 

 * You have to adhere to specific maintenance windows. 
 * You want to manually review potential database schema changes, and have a human present in case a migration fails. 
 * You have other processes that require a manual review. 

 
In these cases, you may need to manually run Django commands against your deployment. 

Cloud Run doesn't provide a way to run one-off shell commands directly on a running container. Instead, you will need to configure Cloud SQL Proxy, and run a locally built image of your application. 

This section describes how this can be achieved, assuming you have completed the initial unicodex deployment. 

---

**Note**: This section details with performing adhoc database commands on live databases, and download local credential files to local file systems. Ensure you understand the processes before performing any commands. 

---

In the [testing locally](00-test-local.md) section, we used `docker-compose.yml` to run a local SQLite database against our Django application. This time, we will use a similar manifest, that uses a proxy image that will connect to our production database from our local machine. 

### docker-proxy.yml

```yaml
version: '3'

services:
  unicodex:
    build: .
    volumes:
      - .:/app
    ports:
      - "8080:8080"

  cloudsql-proxy:
      container_name: cloudsql-proxy
      image: gcr.io/cloudsql-docker/gce-proxy
      command: /cloud_sql_proxy --dir=/cloudsql -instances=PROJECT_ID:REGION:psql=tcp:0.0.0.0:5432 -credential_file=/secrets/cloudsql/credentials.json 
      ports:
        - 5432:5432
      volumes:
        - ./credentials.json:/secrets/cloudsql/credentials.json
      restart: always
```

*This manifest is based on [this stack overflow answer](https://stackoverflow.com/a/48431559/124019)*.

**What this manifest does**: It uses a docker image of the [Cloud SQL Proxy](https://github.com/GoogleCloudPlatform/cloudsql-proxy) in a container named `cloudsql-proxy`. It maps to your instance, using your credentials file. It also explicitly uses a name for the web container. If in later commands you miss the `-f` flag, you will otherwise end up running the existing `docker-compose.yml` file, using the local database. 

**What you need to do**: 
 
 * Replace `PROJECT_ID:REGION` with your project ID and region.
 * Provide credentials and secrets.

For credentials: Previously we could have relied on local `gcloud` settings, but given these commands will be run in a containerised environment, they need to be explicit. 

You can either create a new service account like in [section one](10-setup-gcp.md), or re-use this account.

Save a copy of the credentials locally: 

```shell,exclude
gcloud iam service-accounts keys create credentials.json \
  --iam-account youraccount@${PROJECT_ID}.iam.gserviceaccount.com 
```

For settings: You will also need to use an altered version of your `django_settings`; the database name will have to change to suit. 

If you don't still have a local copy of `.env`, download it: 

```shell,exclude
gcloud secrets versions access latest --secret django_settings > .env
```

In this file, replace the `@//cloudsql/PROJECT_ID:REGION:psql` with `@cloudsql-proxy`. This replaces the host name with the fully qualified Cloud SQL instance name with the container name in the manifest. 

The `DATABASE_URL` value should now read: `"postgres://unicodex-django:PASSWORD@cloudsql-proxy/unicodex"`

This file is added automatically in the `web` image by the `volume` line mounting the current folder in to `/app`. 

---

From here, you will need to start the database container: 

```shell,exclude
docker-compose -f docker-proxy.yml up cloudsql-proxy
```

And then in another terminal, run a command against the database. For example, a migration plan: 

```shell, exclude
docker-compose -f docker-proxy.yml run --rm unicodex python manage.py migrate --plan
```

This will show what would be run if a migration were to be executed. If you have completed your migrations, the output should be: 

```
Planned operations:
  No planned migration operations.
```

---

If you want to be able to run `dbshell`, you will have to install `psql` into your original docker image. 

Add the following line to the `Dockerfile`, before the other `RUN` command: 
```exclude
RUN apt-get update && apt-get install postgresql postgresql-contrib -y --no-install-recommends
```

This will update the package index cache within the container, and install postgres, without installing all the other recommended packages. 

You should then be able to build your image and run dbshell: 

```shell,exclude
docker-compose -f docker-proxy.yml build unicodex
docker-compose -f docker-proxy.yml run unicodex python manage.py dbshell
```

You should then get a `psql` shell into your deployed database:

```
psql (11.7 (Debian 11.7-0+deb10u1), server 11.8)
Type "help" for help.

unicodex=>
```

The `server 11.8` is the Postgres 11 server you deployed. 

You can also confirm it's your production server by checking the codepoints you added, compared to your local testing instance: 

```
unicodex=> select * from unicodex_codepoint;
 id |  name   |    description    | codepoint | emojipedia_name  | order
----+---------+-------------------+-----------+------------------+-------
  3 | Runners | Gotta go fast.    | 1F45F     | running-shoe     |     3
  2 | Cloud   | Light and fluffy! | 2601      |                  |     2
  1 | Waving  | Oh hi!            | 1F44B     | waving-hand-sign |     1
(3 rows)
```
