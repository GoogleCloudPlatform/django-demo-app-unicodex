# Experimental System Testing

This repo has multiple deployment methods: 

 * Terraform
 * Cloud Run Button
 * Generated script from the tutorial documentation

This folder attempts to test those. 

## Setup

Create a 'parent' project, with billing enabled. 

Run the script to setup the parent project, and create a CI project that will actually get the deployment

```
source experimental/setup.sh
```

It will output a CI_PROJECT. Use that in the next steps

## Choose your flavour

```
gcloud builds submit --config experimental/CHOICE_test.yaml --substitutions _CI_PROJECT=$CI_PROJECT --timeout 1500
```

This should *Just work*, exercising each deployment method and checking deployment with the `./util/helper`.