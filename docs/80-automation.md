# Automation

The last several pages of tutorial information was complex, but should have provided some insight as to what was being configured. 

We don't have to do this manual process every time we create a new project. It makes sense to do it at least *once*, to learn and understand what's going on. 

But for deploying multiple setups, such as if you wanted to implement the project seperation suggested in the [last section](70-setup-trigger.md), using provisioning automation makes sense. 

[Terraform](https://www.terraform.io/) allows us to automate infrastructure provisioning, and comes with a [Google Cloud Platform Provider](https://www.terraform.io/docs/providers/google/index.html) out of the box. 


---

This tutorial isn't a full Terraform 101, but it should help guide you along the process. 

Firstly, an installation of Terraform is required: 

```shell,exclude
brew install terraform
```

A basic Cloud Run setup might be as simple as the [provided example](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html): 

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

Or the other examples on that page, for basic [Cloud Run + Cloud SQL](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html#example-usage-cloud-run-service-sql) setup, or [Allow Unauthenticated](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html#example-usage-cloud-run-service-noauth) for example.

But our setup is a little bit more complex. We've provided the Terraform files in `terraform/`, so navigate there and initialise

```shell,exclude
git clone git@github.com/GoogleCloudPlatform/django-demo-app-unicodex
cd django-demo-app-unicodex/terraform
terraform init
```

You'll have to follow the [Getting Started - Adding Credentials](https://www.terraform.io/docs/providers/google/getting_started.html#adding-credentials) section in order to apply any configurations to your project, saving the path to your configuration in `GOOGLE_CLOUD_KEYFILE_JSON`. 


Then, it's a case of running: 

```shell,exclude
terraform apply 
```

This will prompt you for some variables (with details about what's required, see `variables.tf` for the full list), and to check the changes that will be applied (which can be checked without potentially applying with `terraform plan`). 
