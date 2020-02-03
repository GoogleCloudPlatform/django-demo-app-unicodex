This directory serves to store some utility helpers, that are outside of the deployment of unicodex, but help with the demo as a whole.

This is assumed to be advanced operator documentation.  


### Scriptable Deployment

If you look closely at the `docs/`, there are a few "Here's what you could do" sections. These are for scriptability. Using the `shell` markers in `docs/`, it's possible to extract all the code to a single file to at least somewhat automate the setup.

We can also make placeholder substitutions at parse time, to have a script that's all ready for you to run.

To generate: 

```
python .util/parse_docs.py docs/ \
	--project-id YourProjectID \
	--instance-name YourInstanceName \
	--region us-central1 \
	> deploy.sh
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

### Variable debugging

Humans running the tutorial may run into issues if they don't execute all the variable declarations. This script uses the `parse_docs.py` util with a different flag to generate all the commands required to echo out the state of the local terminal. In theory this should make it obvious when something hasn't been declared. 

To generate: 

```
python .util/parse_docs.py docs/ --variables
```

The output will generate a series of `echo` commands. 

Note: this helper is only for manual deployments, and will not work with the scriptable deployment helper above. Why? Because the variables aren't in your local terminal, but defined in the bash subprocess, so this debugging is moot. 
