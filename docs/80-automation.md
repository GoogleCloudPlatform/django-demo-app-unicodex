# Automation

If you're joining us after having completed the rest of the tutorial, it was complex, but should have provided some insight as to what was being configured. 

We don't have to do this manual process every time we create a new complex service. It makes sense to do it at least *once*, to learn and understand what's going on. 

But for deploying multiple setups, such as if you wanted to implement the project separation suggested in the [last section](60-ongoing-deployments.md), using provisioning automation makes sense. 

[Terraform](https://www.terraform.io/) allows us to automate infrastructure provisioning, and comes with a [Google Cloud Platform Provider](https://www.terraform.io/docs/providers/google/index.html) out of the box. 

This tutorial isn't a full Terraform 101, but it should help guide you along the process. 

💡 If you want to, run this section in a new project. That way you can compare and constrast to your original project. Ensure you set your `gcloud config set project` and `$PROJECT_ID` before continuing!

---

## Install Terraform and setup authentication

To start with, you'll need to [install Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) for your operating system. 

Once that's setup, you'll need to create a [new service account](https://www.terraform.io/docs/providers/google/getting_started.html#adding-credentials) that has Owner rights to your project, and [export an authentication key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys) to that service account that Terraform can use. 

```shell,exclude
# Setup gcloud for your project
export PROJECT_ID=YourProjectID
gcloud config set project $PROJECT_ID

# Create the service account
gcloud iam service-accounts create terraform \
  --display-name "Terraform Service Account"

# Grant owner permissions
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member serviceAccount:terraform@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/owner

# create and save a local private key
gcloud iam service-accounts keys create ~/terraform-key.json \
  --iam-account terraform@${PROJECT_ID}.iam.gserviceaccount.com 

# store location of private key in environment that terraform can use
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json

# enable the resource API and IAM APIs
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com
```

---

🤔 Didn't we already do this authentication step?

We did, back in [the GCP setup section](10-setup-gcp.md); we authenticated to let `gcloud` act as "us". Us, in this case, is your login to the Google Cloud Console. There you get the Project Owner role, which is universal admin rights. There are some parts of this setup that require the same level of access as "us". 

---

🧐 But why not just authenticate as ourselves?

You could use `gcloud auth application-default login`, and other tutorials may suggest, but we aren't. There are reasons. 

In the identity model that Google Cloud uses, service accounts belong to the project in which they were created. For example, a service account example@yourproject.iam.gserviceaccount.com belongs to the yourproject project. You can grant a service account a role in another project, but it will always be owned by the project in it's identifying email address. 

Your identity (yourname@gmail.com) also belongs to a project, just not one you have access to. It belongs to a Google-owned project. Your account has some special automatic features -- such as automatically being granted Project Owner when you create a new project -- but otherwise it's not much different than a service account.

When requests are issued to provision or alter resources, a number of checks are made before the action is performed: precondition checks, quota checks, and billing access checks. These checks are made on the project in which the credentials belong to, rather than the resource being altered. This means that if you ask to perform actions on your project using your identity, the checks are actually made against the Google-owned project, not your own. 

In order to prevent any potential ownership and issues, it's recommended that for automation tasks you create a dedicated service account within the project you are performing automations. 


---

To give an overview of how you can use terraform, a basic Cloud Run setup might be as simple as the [provided example](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html). 

This page has other sample provisionings, such as [Cloud Run + Cloud SQL](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html#example-usage-cloud-run-service-sql) setup, or [Allow Unauthenticated](https://www.terraform.io/docs/providers/google/r/cloud_run_service.html#example-usage-cloud-run-service-noauth) for example.

Our setup is a little bit more complex than a 'Hello World', so we're going to provision and deploy in a few steps: 

 * [*Provision*](#provision-infrastructure) the infrastructure with Terraform, then
 * perform the initial [*migration*](#migrate-the-database), then setup
 * Continuous [*Deployment*](#continuous-deployment).
 
 
There is a reason for this separation. All the manual configurations required to get our sample application out into the real world were detailed in the last half-dozen pages of this tutorial. The *provisioning* itself was most of that. But we can use Terraform to re-create all that once. However, when you run Terraform on your local machine, you run Terraform in the same Owner permissions you run `gcloud` with. It makes sense to keep the manual configuration with these permissions, but for automated processes -- such as our triggers -- it makes sense to keep these processes to the minimum possible permissions. This has consequences in the scripts we use to deploy, so to mitigate that, we'll do a manual deployment once, which creates our service. Then, our updates can happen with the most focused permissions required. 

---

### Provision Infrastructure

We've provided the Terraform files in `terraform/`, so navigate there and initialise:

```shell,exclude
git clone https://github.com/GoogleCloudPlatform/django-demo-app-unicodex
```

💡 If you chose to run this section in a new project, you will need to re-create the base image: 

```shell,exclude
gcloud builds submit --tag gcr.io/${PROJECT_ID}/unicodex .
```

Once you have this configured, you need to initialise Terrafrom:

```shell,exclude
cd terraform
terraform init
```

Then apply the configurations: 

```shell,exclude
terraform apply
```

Without specifying any other flags, this command will prompt you for some variables (with details about what's required, see `variables.tf` for the full list), and to check the changes that will be applied (which can be checked without potentially applying with `terraform plan`). 

You can specify your variables using [command-line flags](https://learn.hashicorp.com/terraform/getting-started/variables.html#command-line-flags), which would look something like this: 

```shell,exclude
terraform apply \
  -var region=us-central1 \
  -var service=unicodex \
  -var project=${PROJECT_ID} \
  -var instance_name=psql
```

⚠️ Since we are dynamically creating our secret strings, our [terraform state is considered sensitive data](https://www.terraform.io/docs/state/sensitive-data.html).


Looking within `terraform/`, you'll see we're separating our Terraform process into some major segments: 

 * Enabling the service APIs (which then allows us to)
 * Create the Cloud SQL database (which then allows us to)
 * Create the secrets, permissions, and other components required, to finally allow us to
 * Create the Cloud Run service.

This separation means we can stagger out setup where core sections that depend on each other are completed one at a time. 

### Migrate database

Once this processes finishes, everything will be setup ready for our build-migrate-deploy: 

```shell,exclude
cd ..
gcloud builds submit --config .cloudbuild/build-migrate-deploy.yaml \
  --substitutions="[generated from terraform inputs]"
```

It will also show how to log into the Django admin, including how to retrieve the login secrets: 

```shell,exclude
gcloud secrets versions access latest --secret SUPERUSER
gcloud secrets versions access latest --secret SUPERPASS
``` 

🗒 The secret values are stored in the [local terraform state](https://www.terraform.io/docs/state/index.html), but it's always a good idea to get configurations from the one source of truth.

ℹ️ Unlike the shell scripts we used earlier, we can re-`apply` terraform at any time. So if you have any component that doesn't seem to work, or you manually change something and want to change it back, just run `terraform apply` again. This can help with issues of eventual consistency, network latency, or any other gremlins in the system. 

---

ℹ️ A note on permissions: 

This tutorial has two methods of provisioning: the shell scripts you saw earlier, and the Terraform scripts. Both setups are designed to produce the same project setup in the end, which means that although we could automate more in Terraform (such as creating the Cloud Run service), that would require a different set of permissions for the unicodex service accounts. 

We granted Owner rights for the Terraform service account, as we are running it only locally on our own laptops. If you want to use Terraform within Cloud Build, you should absolutely use a lower level of access. 

---

### Continuous deployment

Once this *provisioning* and *first deploy* is done, you can configure the *automated deployment* as in the [last step](60-ongoing-deployments.md), which is effectively setting up the last command in our above script to trigger automatically. 

---

Don't forget to [clean-up](90-cleanup.md) your resources if you don't want to continue running your app. 

---

