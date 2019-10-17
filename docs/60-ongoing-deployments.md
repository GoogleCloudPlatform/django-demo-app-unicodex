
# Ongoing Deployments

*In this step, we're going to automate the deployment we manually executed in the last step*

---

### *Cloud Build Triggers is in beta*

Please note that the following descriptions may change as functionality is updated in this beta. 

---

We're going to get our service setup with continuous deployment by adding a build trigger through Cloud Build. 

To start, you'll need to have your copy of this repo code setup in it's own repo. We'll be using GitHub (as that's what the project itself uses), but you can do this with BitBucket or Cloud Source Repositories. 

We're going to setup our `master` branch to deploy to our `unicodex` service on merge. 

---

To setup our triggers, we're going to have to go to the [Cloud Build triggers](https://console.cloud.google.com/cloud-build/triggers/) page in the console, and click [Connect repository](https://console.cloud.google.com/cloud-build/triggers/connect). 

From here, you'll need to sign into GitHub, then install Google Cloud Build as an application, against your repository (or all repositories, if you wish.)

**Note**: If you have already installed Cloud Build and did not allow access to all repositories, you'll have to add more from the "Edit repositories on GitHub ⬀" link. 

Then, select the repo you have this code in, noting the disclaimer on access rights. 

Finally, click 'Skip' to skip implementing the suggested default trigger. We'll be making our own. 

---

Now that we've connected our accounts, we can setup the trigger. 

Click the 'Add trigger' from the "..." menu on your repo. 

From here, we're going to enter the following details: 

* **Description**: push on master
* **Branch (regex)**: master
* **Build configuration**: Cloud Build configuration file
* **Cloud Build configuration file location**: `.cloudbuild/build-migrate-deploy.yaml`
* **Substitution variables**:
  * `_IMAGE`: unicodex
  * `_DATABASE_INSTANCE`: yourproject:yourregion:yourinstance
  * `_SERVICE`: unicodex
  * `_BERGLAS_BUCKET`: yourproject-secrets
 
---

With this setup, any time we push code to the `master` branch, our service will be deployed. 

This works well when you have Pull Requests in Github being merged to the `master` branch: any merged PR will automatically initalise a new deployment. 

---

We only implemeted one trigger here. 

You could customise this for your own project in a number of ways. 

Perhaps make use of the [included files](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds#build_trigger) feature, and trigger a build that makes database migrations only if there have been changes to files in `unicodex/migrations/*`. You could then remove that step from the unconditional `master` branch build.

Using [substituion variables](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values#using_user-defined_substitutions), you could setup multiple triggers: ones that on master deploy to a staging environment, and on a tagged release deploy to production. Changing the substitution variables allows you to use the same code and aim the deploy at different places. 

You could also take advantage of [build concurrency](https://cloud.google.com/cloud-build/docs/configuring-builds/configure-build-step-order), if you have steps that don't need to be run one at a time.

You can always also skip builds entirely if the commit messages includes the string [[`skip ci`](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds#skipping_a_build_trigger)]

---

Next step: None! You're done! 🧁

---
