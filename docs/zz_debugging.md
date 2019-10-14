# 🐛🐛🐛 Debugging Steps 🐛🐛🐛 

## Enable `DEBUG` mode in Django

For security reasons, `DEBUG` should not be enabled in production. So, we didn't set it as enabled. 

To temporary enable it:

```
gcloud beta run services update unicodex --update-env-vars DEBUG=True
```

You should then reload the page, and see a more useful error. 

Remember to turn it off again!

```
gcloud beta run services update unicodex --update-env-vars DEBUG=False
```


## Database issues

Is your `DATABASE_URL` correct? Test it with `cloud_sql_proxy`!

Install the [`cloud_sql_proxy` client](https://cloud.google.com/sql/docs/postgres/sql-proxy#install) for your platform. For example, on macOS: 

```
curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
chmod +x cloud_sql_proxy
```

Then, we're going to test our `DATABASE_URL`:

In a new terminal:

```
./cloud_sql_proxy
```

Then, in your original terminal: 

```
pip install psycopg2-binary
python -c "import os, psycopg2; conn = psycopg2.connect(os.environ['DATABASE_URL']);"
```

If this did not return an error, then it all worked!

*So what did we just do?*

We installed a pre-compiled PostgreSQL database adapter, [psycopg2-binary](https://pypi.org/project/psycopg2-binary/). We then started up the `cloud_sql_proxy` in a new tab. Finally, we ran a tiny bit of Python that used the used the PostgreSQL adapter and created a connection using our DATABASE_URL variable. 