# Experimental System Testing

This repo has multiple deployment methods: 

 * Terraform (`terraform`)
 * Cloud Run Button (`button`)
 * Generated script from the tutorial documentation (`gen`). 

This folder attempts to test those. 

⚠️ This setup relies on Preview functionality, and requires a Workspace account (to automate creating projects to test). 

## project_setup.sh

Your Workspace administrator will need to create a base project with billing enabled (to run the script in), and a base folder (where the ephemeral projects will live, identified by `$_PARENT_FOLDER`)

Running this script will setup the current project in a state that it will be ready to be used as a parent project.

```
source experimental/project_setup.sh
```

This will do a number of things, including setup a custom service account, mandatory for later steps. 

## cloudbuild.yaml 

A hands off way to do full testing. WIP. 

With the parent project setup, it will run the test, as if it were running: 

```
source experimental/setup.sh [terraform|button|gen]
./util/helper check-deploy.sh
```

This will create a new project. If you want to use an existing project, specify `_CI_PROJECT` (the script will check if this project exists, if not, create it.)


## Cloud Build triggers

`cloudbuild.yaml` is configured in such a way that it can be run periodically as a trigger. 

1. Go to Cloud Build and [create a trigger](https://console.cloud.google.com/cloud-build/triggers/add)
1. Use these settings: 
   1. Event: Manual Invocation
   1. Source: your repo (click "Connect Repository" if you haven't configured it before)
   1. Branch: your main branch
   1. Configuration: Repository; `experimental/cloudbuild.yaml`
   1. Subsitutions: 
      1. `_PARENT_FOLDER`: the ID of the folder to create builds in
      1. `_TEST_TYPE`: one of: terraform, gen, or button. 
   1. Service Account: ci-serviceaccount@PROJECT_ID.iam.gserviceaccount.com
1. Test the build by clicking 'Run'
1. Make the run periodic by clicking the three veritical dots on the Trigger record, and specifying a schedule. 

Note that you have a maximum amount of projects allowed by default, and projects are only purge-deleted 30 days after you 'delete' them (this allows you a grace period to undelete, etc). Ensure you restrict your test frequency within this limit. 

## Cloud Builds local machine

To test the builds ad-hoc on your local machine, you will need to add the service account inline: 

```
echo "serviceAccount: projects/${PROJECT_ID}/serviceAccounts/ci-serviceaccount@${PROJECT_ID}.iam.gserviceaccount.com" >> experimental/cloudbuild.yaml
```

Then call as you would the main test: 

```
gcloud builds submit --config experimental/cloudbuild.yaml --substitutions _TEST_TYPE=terraform
```
