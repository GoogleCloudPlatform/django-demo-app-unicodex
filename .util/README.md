This directory holds `helper`, a CLI to help with Unicodex. 

This helper does require some setup: 

```
python -m venv venv
source venv/bin/activate
python -m pip install -r .util/requirements.txt
.util/helper --help
```

Additionally, `googleapiclient.discovery` requires authentication, so setup a dedicated service
account:

```
gcloud iam service-accounts create robot-account \
    --display-name "Robot account"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member serviceAccount:robot-account@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/owner
gcloud iam service-accounts keys create ~/robot-account-key.json \
    --iam-account robot-account@${PROJECT_ID}.iam.gserviceaccount.com
export GOOGLE_APPLICATION_CREDENTIALS=~/robot-account-key.json
```

### `gen` - generate a scriptable deployment

If you look closely at the `docs/`, there are a few "Here's what you could do" sections. These are for scriptability. Using the `shell` markers in `docs/`, it's possible to extract all the code to a single file to at least somewhat automate the setup.

We can also make placeholder substitutions at parse time, to have a script that's all ready for you to run.

To generate: 

```
.util/helper gen > deploy.sh
```

Then, in either a Cloud Shell or your local machine: 

```
time bash -ex deploy.sh
```

Notes: 

* Your passwords will be echoed in the output. 
* The entire process will take ~5-10 minutes
* You *can* run this on your local machine, assuming:  
 * You're running macOS or a Linux variant
 * You have `gcloud` installed and configured. 

ℹ️  This script serves as a test of the tutorial, and 'works', but is not really a complete replacement for the terraform Infrastructure as Code approach. 

---

### `check-env` - environment variable debugging

Humans running the tutorial may run into issues if they don't execute all the
variable declarations. This script uses the functionality from `gen`
to parse all environment variables declare in the tutorial, and report their values. 

In theory, this should make it obvious when part of the tutorial was missed. 

To generate: 
```
.util/helper check-env
```

Note: this helper is only for manual deployments, and will not work with the
scriptable deployment helper above. Why? Because the variables aren't in your
local terminal, but defined in the bash subprocess, so this debugging is moot. 

### `check-deploy` - live introspection of a deployment

Unicodex is complex, and even if you think you have remembered to toggle all the switches, you may end up missing something. 
This helper attempts to inspect a live deployment of unicodex for common misconfigurations. 

To use, follow the setup instructions in the top comment of `.util/deployment_checks.py`
to setup a dedicated service account that has access to perform all the checks required, then run:

```
.util/helper check-deploy $PROJECT_ID
```

It will assume the default values for region, service, and django settings secret, but you can override these if required.
