# Unicodex

Let's build a demo application, using a whole bunch o' Google Cloud components. Let's make it just like [emojipedia](https://emojipedia.org/), but let's call it... 

✨ [unicodex](https://unicodex.gl.asnt.app/) ✨

Unicodex uses: 

 * [Django 2.2](https://docs.djangoproject.com/en/2.2/) as the web framework
 * [Google Cloud Run](https://cloud.google.com/run/) as the hosting platform
 * [Google Cloud SQL](https://cloud.google.com/sql/) as the managed database, via [django-environ](https://django-environ.readthedocs.io/en/latest/)
 * [Google Cloud Storage](https://cloud.google.com/storage/) as the media storage platform, via [django-storages](https://django-storages.readthedocs.io/en/latest/)
 * [Google Cloud Build](https://cloud.google.com/cloud-build/) for build and deployment automation
 * [Google KMS](https://cloud.google.com/kms/) for secret storage, via [berglas](https://github.com/GoogleCloudPlatform/berglas)

*This repo serves as a proof of concept of showing how you can piece all the above technolgies together into a working project.*

## Steps

1. [Try the application locally](docs/00-test-local.md) *optional*
2. [Setup Google Cloud Platform environment](docs/10-setup-gcp.md)
3. [Create a Cloud SQL Instance](docs/20-setup-sql.md)
4. [Create a Cloud Storage Bucket](docs/30-setup-bucket.md)
5. [Create some Berglas Secrets](docs/40-setup-secrets.md)
6. [First Deployment](docs/50-first-deployment.md)
7. [Ongoing Deployments](docs/60-ongoing-deployments.md)

## Application Design

### Unicodex itself

[Emojipedia](https://emojipedia.org/) curates information about emoji and how they are represented on different platforms. E.g. the [Sparkles emoji](https://emojipedia.org/sparkles/) (✨) is mostly represented by three golden stars in a cluster, but this has changed over the years (click the sparkle image marked "Google" and you'll see how Sparkles has appeared in every version of Android over the years. It used to look *very* different!)

In Unicodex, these relations are represented by a **codepoint** (Sparkles) having multiple **designs** (images). Each image represents a **version** from a **vendor** (e.g. Google Android 9.0, Twitter Twemoji 1.0, ...). These relations are represented by four models: `Codepoint`, `Design`, `VendorVersion` and `Vendor`, respectively. Designs have a FileField which stores the image. 

In the django admin, an admin action has been setup so that you can select a Codepoint, and run the "Generate designs" actions. This will -- for all configured vendors and vendor versions -- scrape Emojipedia for the information. Alternatively, you can enter this information manually from the django admin. 


### Service design - 1:1:1

Unicodex runs as a Cloud Run service. Using the Python package `django-storages`, it's been configured to take a `GS_BUCKET_NAME` as a storage place for its media. Using the Python package `django-environ` it takes a complex `DATABASE_URL`, which will point to a Cloud SQL postgres database. These are all designed to live in the same Google Cloud Project.

In this way, Unicodex runs 1:1:1 -- one Cloud Run Service, one Cloud SQL Database, one Google Storage bucket. It also assumes that there is *only* one service/database/bucket. 

This implementation is live at [https://unicodex.gl.asnt.app/](https://unicodex.gl.asnt.app/)

### Other service designs

With a few find/replace of some critical values, this setup can be converted to have multiple versions of the service each having their own database in a shared instance. More information for this can be found in the [.util](.util/README.md) directory. 

### TODO

* implement custom database *name* (as well as instance)
* allow multiple `CURRENT_HOST` values (useful when handling custom domains)


## Contributions

Please see the [contributing guidelines](CONTRIBUTING.md)

## License

This library is licensed under Apache 2.0. Full license text is available in [LICENSE](LICENSE)


