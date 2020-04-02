# Unicodex

Let's build a demo application, using a whole bunch o' Google Cloud components. Let's make it just like [emojipedia](https://emojipedia.org/), but let's call it... 

✨ [unicodex](https://unicodex.gl.asnt.app/) ✨

Unicodex uses: 

 * [Django 3.0](https://docs.djangoproject.com/en/3.0/) as the web framework
 * [Google Cloud Run](https://cloud.google.com/run/) as the hosting platform
 * [Google Cloud SQL](https://cloud.google.com/sql/) as the managed database, via [django-environ](https://django-environ.readthedocs.io/en/latest/)
 * [Google Cloud Storage](https://cloud.google.com/storage/) as the media storage platform, via [django-storages](https://django-storages.readthedocs.io/en/latest/)
 * [Google Cloud Build](https://cloud.google.com/cloud-build/) for build and deployment automation
 * [Google Secret Manager](https://cloud.google.com/secret-manager/) for managing encrypted values

*This repo serves as a proof of concept of showing how you can piece all the above technologies together into a working project.*

## Steps

[Try the application locally](docs/00-test-local.md) *optional*

Manual deployment:

1. [Setup Google Cloud Platform environment](docs/10-setup-gcp.md)
1. [Create a Cloud SQL Instance](docs/20-setup-sql.md)
1. [Create a Cloud Storage Bucket](docs/30-setup-bucket.md)
1. [Create some Secrets](docs/40-setup-secrets.md)
1. [First Deployment](docs/50-first-deployment.md)
1. [Ongoing Deployments](docs/60-ongoing-deployments.md)

Automated deployment: 

* [Deploy with Terraform](docs/80-automation.md)

Cleanup: 

* [Cleanup your project resources](docs/90-cleanup.md)


## Application Design

### Unicodex itself

[Emojipedia](https://emojipedia.org/) curates information about emoji and how they are represented on different platforms. E.g. the [Sparkles emoji](https://emojipedia.org/sparkles/) (✨) is mostly represented by three golden stars in a cluster, but this has changed over the years (click the sparkle image marked "Google" and you'll see how Sparkles has appeared in every version of Android over the years. It used to look *very* different!)

In Unicodex, these relations are represented by a **codepoint** (Sparkles) having multiple **designs** (images). Each image represents a **version** from a **vendor** (e.g. Google Android 9.0, Twitter Twemoji 1.0, ...). These relations are represented by four models: `Codepoint`, `Design`, `VendorVersion` and `Vendor`, respectively. Designs have a FileField which stores the image. 

In the django admin, an admin action has been setup so that you can select a Codepoint, and run the "Generate designs" actions. This will -- for all configured vendors and vendor versions -- scrape Emojipedia for the information. Alternatively, you can enter this information manually from the django admin. 


### Service design - 1:1:1

Unicodex runs as a Cloud Run service. Using the Python package `django-storages`, it's been configured to take a `GS_BUCKET_NAME` as a storage place for its media. Using the Python package `django-environ` it takes a complex `DATABASE_URL`, which will point to a Cloud SQL PostgreSQL database. The `settings.py` is also designed to pull specifically named secrets into the environment. These are all designed to live in the same Google Cloud Project. Secrets are given specific names. 

In this way, Unicodex runs 1:1:1 -- one Cloud Run Service, one Cloud SQL Database, one Google Storage bucket. It also assumes that there is *only* one service/database/bucket. 

This implementation is live at [https://unicodex.gl.asnt.app/](https://unicodex.gl.asnt.app/)

### Other service designs

It is possible to host multiple instances of Unicodex on the one project (where the service name, bucket name, and database name, and django database username have different appended 'slugs', and all share one instance), but this configuration is out of scope for this project. 

You can host multiple versions of Unicodex using project isolation (one Google Cloud account can have multiple projects) without any code editing, but this may not work for your own project. [Read more about project organisation considerations](https://cloud.google.com/docs/enterprise/best-practices-for-enterprise-organizations#project-structure)


## Contributions

Please see the [contributing guidelines](CONTRIBUTING.md)

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE).

