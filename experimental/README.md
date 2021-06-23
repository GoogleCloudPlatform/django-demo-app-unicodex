# Experimental System Testing

This repo has multiple deployment methods: 

 * Terraform
 * Cloud Run Button
 * Generated script from the tutorial documentation

This folder attempts to test those. 

## project_setup.sh

With an existing project with billing enabled, running this script will setup the current project in a state that it will be ready to be used as a parent project.

```
source experimental/project_setup.sh
```

## cloudbuild.yaml 

A hands off way to do full testing. WIP. 

With the parent project setup, it will run the test, as if it were running: 

```
source experimental/setup.sh [terraform|button|gen]
./util/helper check-deploy.sh
```

