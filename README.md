# ✨ [unicodex](https://unicodex.gl.asnt.app/) ✨

Unicodex is a demo database-backed serverless Django application, that uses: 

 * [Django](https://djangoproject.com/) as the web framework,
 * [Google Cloud Run](https://cloud.google.com/run/) as the hosting platform,
 * [Google Cloud SQL](https://cloud.google.com/sql/) as the managed database (via [django-environ](https://django-environ.readthedocs.io/en/latest/)), 
 * [Google Cloud Storage](https://cloud.google.com/storage/) as the media storage platform (via [django-storages](https://django-storages.readthedocs.io/en/latest/)),
 * [Google Cloud Build](https://cloud.google.com/cloud-build/) for build and deployment automation, and
 * [Google Secret Manager](https://cloud.google.com/secret-manager/) for managing encrypted values.

## Deployment

This demo can be deployed by multiple different methods: via the Cloud Run button, through Terraform, or manually via a guided tutorial.  

### Automated

[![Run on Google Cloud](https://deploy.cloud.run/button.svg)](https://deploy.cloud.run)

See `app.json` and the `.gcloud/` folder for implementation details.

### Terraform 

* Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) and setup [authentication](docs/80-automation.md#install-terraform-and-setup-authentication)
* Use Terraform to [provision infrastructure](docs/80-automation.md#provision-infrastructure)
* Use Cloud Build to perform the initial [database migration](docs/80-automation.md#migrate-database)

See `terraform/` for configuration details.

### Manual

* [Try the application locally](docs/00-test-local.md) (*optional*)
* Setup your [Google Cloud environment](docs/10-setup-gcp.md), then provision backing services: 
  * a [Cloud SQL Instance](docs/20-setup-sql.md),
  * a [Cloud Storage Bucket](docs/30-setup-bucket.md), and
  * some [Secrets](docs/40-setup-secrets.md), then
* Run your [first deployment](docs/50-first-deployment.md)
* Automate [ongoing deployments](docs/60-ongoing-deployments.md) (*optional*)

Don't forget to [cleanup your project resources](docs/90-cleanup.md) when you're done!

## Application Design

### Unicodex itself

[Emojipedia](https://emojipedia.org/) curates information about emoji and how they are represented on different platforms. E.g. the [Sparkles emoji](https://emojipedia.org/sparkles/) (✨) is mostly represented by three golden stars in a cluster, but this has changed over the years (click the sparkle image marked "Google" and you'll see how Sparkles has appeared in every version of Android over the years. It used to look *very* different!)

In Unicodex, these relations are represented by a **codepoint** (Sparkles) having multiple **designs** (images). Each image represents a **version** from a **vendor** (e.g. Google Android 9.0, Twitter Twemoji 1.0, ...). These relations are represented by four models: `Codepoint`, `Design`, `VendorVersion` and `Vendor`, respectively. Designs have a FileField which stores the image. 

In the Django admin, an admin action has been setup so that you can select a Codepoint, and run the "Generate designs" actions. This will -- for all configured vendors and vendor versions -- scrape Emojipedia for the information, including uploading images. Alternatively, you can enter this information manually from the django admin. 


### Service design - one deployment per Google Cloud project

Unicodex runs as a Cloud Run service. Using the Python package `django-storages`, it's been configured to take a `GS_BUCKET_NAME` as a storage place for its media. Using the Python package `django-environ` it takes a complex `DATABASE_URL`, which will point to a Cloud SQL PostgreSQL database. The `settings.py` is also designed to pull a specific secret into the environment. These are all designed to live in the same Google Cloud Project.

In this way, Unicodex runs 1:1:1 -- one Cloud Run Service, one Cloud SQL Database, one Google Storage bucket. It also assumes that there is *only* one service/database/bucket. 

This implementation is live at [https://unicodex.gl.asnt.app/](https://unicodex.gl.asnt.app/)

### Other service designs

It is possible to host multiple instances of Unicodex on the one project (where the service name, bucket name, and database name, and django database username have different appended 'slugs', and all share one instance), but this configuration is out of scope for this project. 

You can host multiple versions of Unicodex using project isolation (one Google Cloud account can have multiple projects) without any code editing, but this may not work for your own project. [Read more about project organisation considerations](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations#project-structure)


## Contributions

Please see the [contributing guidelines](CONTRIBUTING.md)

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).

