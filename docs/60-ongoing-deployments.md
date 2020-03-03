
# Ongoing Deployments

*In this step, we're going to automate the deployment we manually executed in the last step*

---

### *Cloud Build Triggers is in beta*

Please note that the following descriptions may change as functionality is updated in this beta. 

---

We're going to get our service setup with continuous deployment by adding a build trigger through Cloud Build. 

To start, you'll need to have your copy of this repo code setup in it's own repo. We'll be using GitHub for this tutorial, but you can also do this a Cloud Source Repository.

If you're unfamiliar with forking a respository, you can follow [GitHub's tutorial on the subject](https://help.github.com/en/github/getting-started-with-github/fork-a-repo). 

We're going to setup our `master` branch on our fork deploy to our `unicodex` service on merge. 

---

Before we can setup our trigger, we're going to have to [connect to our source repository](https://cloud.google.com/cloud-build/docs/running-builds/create-manage-triggers#connecting_to_source_repositories). The full instructions for this are on the [Google Cloud docs page](https://cloud.google.com/cloud-build/docs/running-builds/create-manage-triggers)

You'll need to sign into GitHub, whereever you made a copy of your repo, then install Google Cloud Build as an application against your repository (or all repositories, if you wish.)

**Note**: If you have already installed Cloud Build and did not allow access to all repositories, you'll have to add more from the "Edit repositories on GitHub ⬀" link. 

Then, select the repo you have this code in, noting the disclaimer on access rights. 

Finally, click 'Skip' to skip implementing the suggested default trigger. We'll be making our own. 

---

Now that we've connected our accounts, we can setup the trigger. 

This command is similar to the `gcloud builds submit --config` command we ran in the [last section](50-first-deployment.md), and for good reason. Instead of having to manually choose when we run this command, we're essentially setting up a listener to do this for us. 

For this command, you'll have to define your own GitHub username as the `REPO_OWNER`:

```shell,exclude
REPO_OWNER=you

gcloud beta builds triggers create github \
  --repo-name django-demo-app-unicodex \
  --repo-owner ${REPO_OWNER} \
  --branch-pattern master \
  --build-config .cloudbuild/build-migrate-deploy.yaml \
  --substitutions "_REGION=${REGION},_INSTANCE_NAME=${INSTANCE_NAME},_SERVICE=${SERVICE_NAME}"
```

With this setup, any time we push code to the `master` branch, our service will be deployed. 

You can test that this works by making a pull request on your own repo, merge it, and see your changes automatically deployed. 

What could you change? 
 
 * Want to change the home page from "✨ Unicodex ✨"?
   * Try changing the `block title` on `unicodex/templates/index.html`
 * Want to add another field to the 	Codepoint display?
   * Try adding a new field on the `unicodex/models.py`
   * Be sure to add this new field on `unicodex/templates/codepoint.html`
   * Make sure you run `./manage.py makemigrations` and commit the new `migrations` file it generates!
 * Want to add something more?
   * Go wild! ✨

---

We only implemented one trigger here. 

You could customise this for your own project in a number of ways. 

Perhaps make use of the [included files](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds#build_trigger) feature, and trigger a build that makes database migrations only if there have been changes to files in `unicodex/migrations/*`. You could then remove that step from the unconditional `master` branch build.

Using [substitution variables](https://cloud.google.com/cloud-build/docs/configuring-builds/substitute-variable-values#using_user-defined_substitutions), you could setup multiple triggers: ones that on master deploy to a staging environment, and on a tagged release deploy to production. Changing the substitution variables allows you to use the same code and aim the deploy at different places. 

You could also take advantage of [build concurrency](https://cloud.google.com/cloud-build/docs/configuring-builds/configure-build-step-order), if you have steps that don't need to be run one at a time.

You can always also skip builds entirely if the commit messages includes the string [[`skip ci`](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds#skipping_a_build_trigger)]

---

Next step: None! You're done! 🧁 

But if you really want to, you can [automate this entire process with Terraform](80-automation.md).

---

Don't forget to [clean-up](90-cleanup.md) your resources if you don't want to continue running your app. 

---

