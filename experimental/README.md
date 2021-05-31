# Experimental System Testing

This repo has multiple deployment methods: 

 * Terraform
 * Cloud Run Button
 * Generated script from the tutorial documentation

This folder attempts to test those. 

## quickstart.sh

A hands off way to do full testing. WIP. 

```
source experimental/quickstart.sh [terraform|button|gen]
```

It will run the setup.sh (below), then kick off one of multiple deployment methods and test the results. 


## setup.sh

With an existing project with billing enabled, running this script will setup the parent project, and create a CI project that will actually get the deployment

```
source experimental/setup.sh
```

It will output a CI_PROJECT. 
