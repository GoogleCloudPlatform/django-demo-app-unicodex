# Django Demo Application - Unicodex

## Deploying a complex serverless application. 

In this tutorial, we're going to deploy a complex service on Cloud Run. 

We'll be touching multiple parts of the Google Cloud Platform in order to configure our application. 

We'll need: 

 * a database to store our data,
 * a storage bucket for our media assets,
 * secrets for securing our access keys,
 * automations to deploy our application,
 * and a Cloud Run service to tie it all together.

The command-line based version of this tutorial can be [found on GitHub](https://github.com/GoogleCloudPlatform/django-demo-app-unicodex#steps)

## Project Setup

Cloud Run needs a project to create resources. 

<walkthrough-project-billing-setup></walkthrough-project-billing-setup>

## Cloud SQL Instance creation

We're going to create a PostgreSQL database to store our data. 

1. Navigate to SQL Instances page
    <walkthrough-menu-navigation sectionId="SQL_SECTION"></walkthrough-menu-navigation>

1. Click [Create instance][spotlight-sql-create-instance]


1. Choose [PostgreSQL][spotlight-sql-postgres-engine]


1.  Configure Instance:

    * [Instance ID][spotlight-sql-instance-id]
    * [Default user password][spotlight-sql-root-password]

1. Click [Create][spotlight-sql-create-save]

[spotlight-sql-create-instance]: walkthrough://spotlight-pointer?cssSelector=.ace-icon-add 
[spotlight-sql-postgres-engine]: walkthrough://spotlight-pointer?spotlightId=sql-mysql-wizard-choose-postgres
[spotlight-sql-instance-id]: walkthrough://spotlight-pointer?spotlightId=sql-instance-id-input
[spotlight-sql-root-password]: walkthrough://spotlight-pointer?spotlightId=sql-root-password-input
[spotlight-sql-create-save]: walkthrough://spotlight-pointer?spotlightId=sql-create-save

## Create a bucket

In Cloud Storage, you store your objects in buckets. To create a bucket, you
need to go to the Cloud Storage browser.

Open the [menu][spotlight-menu] on the left side of the console.

Then, select the **Storage** section.

<walkthrough-menu-navigation sectionId="STORAGE_SECTION"></walkthrough-menu-navigation>

  1. Click [Create bucket][spotlight-storage-create-bucket]

  1. Walk through the Create a Bucket sequence, clicking [Continue][spotlight-continue] at each stage: 
     * **Name your bucket**
        * Think of something unique. You'll see an error if you enter a
     * **Choose where to store your data**
        * Keep in mind additional costs with multi-region. 
     * **Choose a default storage class for your data**
        * Keep to the default **Standard**.
     * **Choose how to control access to objects**
        * Keep to the default **Fine-grained**.
     * **Advanced settings (optional)**
        * Keep to the default **Google managed**. 

  1. Click [Create][spotlight-create-button]


[spotlight-storage-create-bucket]: walkthrough://spotlight-pointer?cssSelector=.ace-icon-create
[spotlight-continue]: walkthrough://spotlight-pointer?cssSelector=.cfc-stepper-step-button
[spotlight-create-button]: walkthrough://spotlight-pointer?cssSelector=cfc-progress-button


## Create some secrets

This section is best explained by the command-line tutorial, which you can follow in the [Cloud Shell][spotlight-cloud-shell]

[Create Berglas secrets - django-demo-app-unicodex tutorial](https://github.com/GoogleCloudPlatform/django-demo-app-unicodex/blob/master/docs/40-setup-secrets.md)

[spotlight-cloud-shell]: walkthrough://spotlight-pointer?spotlightId=devshell-web-preview-button

## Create an image

TODO(glasnt): create an image

## Create a service

Open the [menu][spotlight-menu] on the left side of the console.

Then, select the **Cloud Run** section. 

<walkthrough-menu-navigation sectionId="SERVERLESS_SECTION"></walkthrough-menu-navigation>

Click on the [Create Service][spotlight-create-service] button. 

On the service creation page, specify the services properties: 

* Enter `gcr.io/PROJECTID/unicodex` for the [container Image][spotlight-container-image-url].
* Keep "Cloud Run (fully managed)" for the [platform][spotlight-platform], and select any [location][spotlight-location].
* For the Service settings, 
  * enter `unicodex` for the [service name][spotlight-service-name],
  * select the Cloud SQL instance from earlier.
  * select ["Allow unauthenticated invocations"][spotlight-allow-unauthenticated].

Finally, click [create][spotlight-create].


[spotlight-menu]: walkthrough://spotlight-pointer?spotlightId=console-nav-menu
[spotlight-create-service]:  walkthrough://spotlight-pointer?cssSelector=a[href^="/run/create"]
[spotlight-container-image-url]: walkthrough://spotlight-pointer?cssSelector=gse-container-input
[spotlight-platform]: walkthrough://spotlight-pointer?cssSelector=mat-radio-button[value="managed"]
[spotlight-location]: walkthrough://spotlight-pointer?cssSelector=cfc-select[formControlName="regionLocation"]
[spotlight-service-name]: walkthrough://spotlight-pointer?cssSelector=input[formControlName="name"]
[spotlight-allow-unauthenticated]: walkthrough://spotlight-pointer?cssSelector=mat-radio-button[value="allowed"]
[spotlight-create]: walkthrough://spotlight-pointer?cssSelector=button[type="submit"]
[spotlight-url]: walkthrough://spotlight-pointer?cssSelector=a[cfc-external-link]

## Conclusion

<walkthrough-conclusion-trophy/>

Congratulations! You've just deployed a serverless service!
