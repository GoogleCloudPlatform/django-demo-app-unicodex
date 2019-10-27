This directory serves to store some utility helpers, that are outside of the deployment of unicodex, but help with the demo as a whole.

This is assumed to be advanced operator documentation.  


### Scriptable Deployment

*This is a stopgap until such a time as terraform [supports](https://dev.to/glasnt/on-the-subject-of-learning-terraform-h4d#beta-providers-again) all the required configurations.*

Using the `shell` markers in `docs/`, it's possible to extract all the code to a single file to at least somewhat automate the setup.

We can also make placeholder substitutions at parse time, to have a script that's all ready for you. 

To generate: 

```
python .util/parse_docs.py docs/ \
	--project-id YourProjectID \
	--instance-name YourInstanceName \
	[--region us-central1] [--slug SLUG] \
	> deploy.sh
```

This assumes:

 * The `YourProjectID` project already exists 
 * The `YourInstanceName` database instance already exists

 
Optional arguments:

 * You can set a new `region` (noting it must support both Cloud Run and Cloud SQL)
 * You can set a slug, replacing `unicodex` with `unicodex-SLUG`
 	* this allows you to have, say, `unicodex-qa` aand `unicodex-test` in the same project, moving away from the default 1:1:1 setup.
 	
---

Then, in a Cloud Shell 

```
time bash -ex deploy.sh
```

Your passwords will be echoed in the output. 

The entire process will take ~10-15 minutes, less if you aren't creating a new database instance. 

  
You *can* run this on your local machine, assuming: 

* You're running macOS or a Linux variant
* You have `gcloud`, and `psql`, and `docker` installed locally.


---

To setup for a new run (e.g. debugging): 

* remove created buckets
* remove local clone of code

---

This is a work around. We've tried to make this process repeatable, but it's no replacement for a full Infrastructure as Code solution, such as terraform. 
  