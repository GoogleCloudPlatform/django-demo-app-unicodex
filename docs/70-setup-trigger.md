# Setup Cloud Build trigger

TODO(glasnt): Document design decision and process to setup a [Cloud Build trigger](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds#build_trigger) on master



---

This is only a basic trigger which, on push to master, does all the things. 

You could customise this for your own project in a number of ways. 

Perhaps make use of the [Included files](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds#build_trigger) feature, and trigger a build that makes database migrations only if there have been changes to files in `unicodex/migrations/*`. You could then remove that step from the unconditional `master` branch build.

You could also take advantage of [build concurrency](https://cloud.google.com/cloud-build/docs/configuring-builds/configure-build-step-order), if you have steps that don't need to be run one at a timee.

You can always also skip builds entirely if the commit messages includes the string [[`skip ci`](https://cloud.google.com/cloud-build/docs/running-builds/automate-builds#skipping_a_build_trigger)]

---

Next step: None! You're done! 🧁
