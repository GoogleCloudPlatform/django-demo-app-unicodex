# Unicodex

Let's build a demo application, just like [emojipedia](https://emojipedia.org/), but let's call it... 

✨ unicodex ✨

It uses: 

 * [Django 2.2](https://docs.djangoproject.com/en/2.2/) as the web framework,
 * [Google Cloud Run](https://cloud.google.com/run/) as the hosting platform,
 * [Google Cloud SQL](https://cloud.google.com/sql/) as the managed database, via [django-environ](https://django-environ.readthedocs.io/en/latest/),
 * [Google Cloud Storage](https://cloud.google.com/storage/) as the media storage platform, via [django-storages](https://django-storages.readthedocs.io/en/latest/), and
 * [Google Cloud Build](https://cloud.google.com/cloud-build/) for migration and deployment

*This repo serves as a proof of concept of showing how you can piece all the above technolgies together into a working project.*

## Steps

1. [Try the application locally](docs/00-test-local.md) *optional*
2. [Setup Google Cloud Platform environment](docs/10-setup-gcp.md)
3. [Create a Cloud SQL Instance](docs/20-setup-sql.md)
4. [Create a Cloud Storage Bucket](docs/30-setup-bucket.md)
5. [Create some Berglas Secrets](docs/40-setup-secrets.md)
6. [First Deployment](docs/50-first-deployment.md)
7. [Ongoing Deployments](docs/60-ongoing-deployments.md)
8. [Setup a Cloud Build trigger](docs/70-setup-trigger.md)

## Application Design

### Unicodex itself

[Emojipedia](https://emojipedia.org/) curates information about emoji and how they are represented on different platforms. E.g. the [Sparkles emoji](https://emojipedia.org/sparkles/) (✨) is mostly represented by three golden stars in a cluster, but this has changed over the years (click the sparkle image marked "Google" and you'll see how Sparkles has appeared in every version of Android over the years)

In Unicodex, this functionality is represented by: a **codepoint** (Sparkles) having multiple **designs** (images). Each image represents a **version** from a **vendor** (e.g. Google Android 9.0, Google Andoird 8.0...). These are represented with four models: `Codepoint`, `Design`, `VendorVersion` and `Vendor`, respectively. Designs have a FileField which stores the image. 

In the Django Admin, an admin action has been setup so that you can select a Codepoint, and run the "Generate designs" actions. This will, for all known vendors and vendor versions, scrape Emojipedia for this information. You can always enter this information manually from the django admin. 


### Service design - 1:1:1

Unicodex runs as a Cloud Run service. Using the Python package `django-storages`, it's been configured to take a `GS_BUCKET_NAME` as a storage place for its media. Using the Python package `django-environ` it takes a complex `DATABASE_URL`, which will point to a Cloud SQL postgres database. These are all designed to live in the same Google Cloud Project. The Triggers setup then configures the master branch the repo to deploy to this environment.

In this way, Unicodex runs 1:1:1 -- one Cloud Run Service, one Cloud SQL Database, one Google Cloud Project.

This implementation is live at https://unicodex.gl.asnt.app/

### Other service designs

While the documentation details how to setup a 1:1:1 configuration, with automation steps this could be configured to have a more complex design. For example: one project with one database instance hosting multiple databases, each of those linking to a separate service. This could work for a QA environment, where each developer gets their own "unicodex in a box". Complimented with a *seperate* project that serves as the production version, and a series of Cloud Build triggers that, for instance, deploy to prod when a release is tagged.

This configuration is left as an exercise for the reader. 

### TODO

* implement custom database *name* (as well as instance)
* allow multiple `CURRENT_HOST` values (useful when handling custom domains)


## Contributions

Please see the [contributing guidelines](CONTRIBUTING.md)

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE)


