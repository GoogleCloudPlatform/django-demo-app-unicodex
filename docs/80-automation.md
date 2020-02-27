# Automation

If you're joining us after having completed the rest of the tutorial, it was complex, but should have provided some insight as to what was being configured. 

We don't have to do this manual process every time we create a new complex service. It makes sense to do it at least *once*, to learn and understand what's going on. 

But for deploying multiple setups, such as if you wanted to implement the project separation suggested in the [last section](60-ongoing-deployments.md), using provisioning automation makes sense. 

[Terraform](https://www.terraform.io/) allows us to automate infrastructure provisioning, and comes with a [Google Cloud Platform Provider](https://www.terraform.io/docs/providers/google/index.html) out of the box. 

---

This tutorial isn't a full Terraform 101, but it should help guide you along the process. 

To start with, you'll need to [install Terraform for your operating system](https://learn.hashicorp.com/terraform/getting-started/install.html), and [setup your local credentials](https://cloud.google.com/docs/authentication/production#obtaining_and_providing_service_account_credentials_manually) (we did something similar earlier, just create a "terraform-provision" service as an owner and save your key somewhere outside of your project code).

To give an overview of how you can use terraform, a basic Cloud Run setup might be as simple as the [provided example](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html): 

```shell,exclude
resource "google_cloud_run_service" "default" {
  name     = "tftest-cloudrun"
  location = "us-central1"

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
      }
    }
  }
}
```

This page has other sample provisionings, such as [Cloud Run + Cloud SQL](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html#example-usage-cloud-run-service-sql) setup, or [Allow Unauthenticated](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html#example-usage-cloud-run-service-noauth) for example.

---

Our setup is a little bit more complex than a 'Hello World', so we're going to provision and deploy in a few steps: 

 * [*Provision*](#provision-infrastructure) the infrastructure with Terraform, then
 * [*Create*](#create-service) the service manually once, then we can setup
 * Continuous [*Deployment*](#continuous-deployment).
 
 
There is a reason for this separation. All the manual configurations required to get our sample application out into the real world were detailed in the last half-dozen pages of this tutorial. The *provisioning* itself was most of that. But we can use Terraform to re-create all that once. However, when you run Terraform on your local machine, you run Terraform in the same Owner permissions you run `gcloud` with. It makes sense to keep the manual configuration with these permissions, but for automated processes -- such as our triggers -- it makes sense to keep these processes to the minimum possible permissions. This has consequences in the scripts we use to deploy, so to mitigate that, we'll do a manual deployment once, which creates our service. Then, our updates can happen with the most focused permissions required. 

---

### Provision Infrastructure

We've provided the Terraform files in `terraform/`, so navigate there and initialise:

```shell,exclude
git clone git@github.com/GoogleCloudPlatform/django-demo-app-unicodex
cd django-demo-app-unicodex/terraform
```

You'll also have to follow the [Getting Started - Adding Credentials](https://www.terraform.io/docs/providers/google/getting_started.html#adding-credentials) section in order to apply any configurations to your project, saving the path to your configuration in `GOOGLE_CLOUD_KEYFILE_JSON`. 

Once you have this configured, you need to initialise Terrafrom:

```shell,exclude
terraform init
```

Then apply the configurations: 

```shell,exclude
terraform apply
```

Without specifying any other flags, this command will prompt you for some variables (with details about what's required, see `variables.tf` for the full list), and to check the changes that will be applied (which can be checked without potentially applying with `terraform plan`). 

You can specify your variables using [command-line flags](https://learn.hashicorp.com/terraform/getting-started/variables.html#command-line-flags), which would look something like this: 

```shell,exclude
terraform apply -var 'region=us-central1' -var 'service=unicodex' -var 'project=MyProject' -var 'instance_name=psql'
```

⚠️ Since we are dynamically creating our secret strings, our [terraform state is considered sensitive data](https://www.terraform.io/docs/state/sensitive-data.html).


Looking within `terraform/`, you'll see we're separating our Terraform process into three major segments: 

 * Enabling the service APIs (which then allows us to)
 * Create the Cloud SQL database (which then allows us to)
 * Create the secrets, permissions, and other components required. 

This separation means we can stagger out setup where core sections that depend on each other are completed one at a time. 

Once this processes finishes, everything will be setup. We could have configured terraform to export values to help with the next step, e.g. your admin password, but you should probably use the Google Cloud Console to `gcloud` to get those directly yourself. (All this information is in the [local terraform state](https://www.terraform.io/docs/state/index.html), but it's always a good idea to get configurations from the one source of truth.)

ℹ️ Unlike the shell scripts we used earlier, we can re-`apply` terraform at any time. So if you have any component that doesn't seem to work, or you manually change something and want to change it back, just run `terraform apply` again. This can help with issues of eventual consistency, network latency, or any other gremlins in the system. 


### Create service

Now the infrastructure is around, we can deploy first time, using the same script from the [first deployment](50-first-deployment.md) section, using the sample values we provided above. 

```shell,exclude
# Build the image
gcloud builds submit --tag gcr.io/MyProject/unicodex .

# Create the service
gcloud run deploy unicodex \
    --allow-unauthenticated \
    --image gcr.io/MyProject/unicodex \
    --add-cloudsql-instances MyProject:us-central1:psql \
    --service-account unicodex@myproject.iam.gserviceaccount.com
   
# Configure the Service URL to be recognised by Django
export SERVICE_URL=$(gcloud run services describe unicodex --format="value(status.url)")
gcloud run services update unicodex --update-env-vars CURRENT_HOST=$SERVICE_URL

# Database migration, creating superuser/pass
gcloud builds submit --config .cloudbuild/build-migrate-deploy.yaml \
    --substitutions="_REGION=us-central1,_INSTANCE_NAME=psql,_SERVICE=unicodex"

```

The output of the last command will show you where your service is deployed. You can use the superuser/pass via `gcloud secrets versions access latest` to log in. 

---

ℹ️ A note on permissions: 

The permissions that Terraform configures are slightly different than the guided walkthrough. In this version of the provisioning process you never run `gcloud`, but Terraform itself is setting up things as you. However, since *you* never setup the Cloud Run service, Cloud Build needs more permissions (there are explicit 'create' permissions that differ from 'update'). 

All this being said, the configuration that terraform sets up is more permissive than the manual process. If you plan to use the terraform configurations as is in your own setup, keep this in mind. 


### Continuous deployment

Once this *provisioning* and *first deploy* is done, you can configure the *automated deployment* as in the [last step](60-ongoing-deployments.md), which is effectively setting up the last command in our above script to trigger automatically. 

---

Don't forget to [clean-up](90-cleanup.md) your resources if you don't want to continue running your app. 

---

