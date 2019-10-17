This directory serves to store some utility helpers, that are outside of the deployment of unicodex, but help with the demo as a whole.

This is assumed to be advanced operator documentation.  


### Scriptable Deployment

*This is a stopgap until such a time as terraform [supports](https://dev.to/glasnt/on-the-subject-of-learning-terraform-h4d#beta-providers-again) all the required configurations.*

Using the `shell` markers in `docs/`, it's possible to extract all the code to a single file to at least somewhat automate the setup.

To generate: 

```
python .util/parse_docs.py docs/ > deploy.sh
```

To deploy: 

 * If your project doesn't already exist: 
   * Create and enable billing. 
 * Replace `YourProjectID` with your project ID
 * Replace `us-central1` with your preferred region
   * noting it must support both Cloud Run and Cloud SQL
 * If your database doesn't exist yet: 
   * Replace `YourInstanceId` with what you want your instance to be called. 
 * If your database exists already: 
   * Replace `YourInstanceID` with your existing database instance ID
   * Replace `PGPASSWORD` with `$(cat /path/to/afilewithyour/PGPASS)`

The setup assumes a 1:1:1 setup. To optionally deploy multiple instances of unicodex in the same project, additionally: 

 * `s/unicodex/$SLUG/` where `$SLUG` could be, for example `unicodex-stage`
 * Replace `BERGLAS_BUCKET` with `${PROJECT_ID}-${SLUG}-secrets`
 * Replace `MEDIA_BUCKET` with `${PROJECT_ID}-${SLUG}-media`
 * Replace `USERNAME` with `${SLUG}-django`


Then run: 

```
bash -ex deploy.sh
```
  
Your passwords will be echoed in the output. 

The entire process will take ~10-15 minutes, less if you aren't creating a new database instance. 