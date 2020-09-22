
# Try the application locally

*Before you get to deploying this application on Google Cloud, you can test the application locally with Docker and Docker Compose.*

*In this section, we'll build the application on our local machine, and using the provided configuration file, we'll deploy the app locally.*

---

You will need to install: 

 * Docker Desktop
   * for Windows or macOS: use [Docker Desktop](https://www.docker.com/products/docker-desktop) 
   * for Linux: use [Docker CE](https://docs.docker.com/install/) ([Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/), [Debian](https://docs.docker.com/install/linux/docker-ce/debian/), [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/), and [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/) have dedicated instructions)
 * [Docker Compose](https://docs.docker.com/compose/install/#install-compose)

This local deployment will use the same image as our production deployment will, but will make use of the included `docker-compose.yml` to connect together the components. 

## Get a local copy of the code

If you are familiar with `git`: 

```
git clone git@github.com:GoogleCloudPlatform/django-demo-app-unicodex
cd django-demo-app-unicodex
```

Otherwise, you can download and extract the latest [release](https://github.com/GoogleCloudPlatform/django-demo-app-unicodex/releases).


## Build the image
 
Before we can use our image, we have to build it. The database image will be pulled down later, so we just need to manually build our web image: 

```
docker-compose build
``` 

## Configure the local environment

Because you'll be running the image locally, you won't want to access Google Cloud services. The Django settings pull configurations
from a service called Secret Manager if a `.env` file doesn't exist locally. 

To bypass this, you will need to create a `.env` file populated with some default values. Use the `.env-local` as a base: 

```
cp .env-local .env
```

This file uses configurations that match the expected values in `docker-compose.yml` for the database connection string, which is the most essential part of this setup.

## Initialise the database

At the moment the database is empty. We can use standard Django commands to run our database migrations, and add some default data; these instructions need to be run the context of our web image: 

```
docker-compose run --rm web python manage.py migrate
docker-compose run --rm web python manage.py loaddata sampledata
```

**Tip**: `docker-compose run --rm` is quite long. You could create an alias for this command in your `.bashrc`. For example: `alias drc=docker-compose run --rm`. Adjust for your choice of terminal.

## Start the services

Now we have a database with data, and a build web image, we can start them: 

```
docker-compose up
``` 

You can now see unicodex running in your browser at [http://localhost:8080/](http://localhost:8080/)


## Testing your installation

If you've loaded the sample data correctly, you'll have a display that shows the Waving emoji.

[Clicking on the emoji][hand] shows the designs for that emoji. Of which, currently, there are none. That's okay, we'll add some. 

Go to the [django admin](http://localhost:8080/admin) and login with the username and password from `docker-compose.yaml`. From there, click on the ["Codepoint" model](http://localhost:8080/admin/unicodex/codepoint/). You should see one listing, `1F44B`. Now, select that listing by clicking on the checkbox on the far left side, and in the Action dropdown, select 'Generate designs for available vendor versions'. 

Your `docker-compose` window will show a lot of output. What this [admin action](https://docs.djangoproject.com/en/2.2/ref/contrib/admin/actions/) is doing is getting the Emojipedia page for ["waving hand sign"](https://emojipedia.org/waving-hand-sign/), and cross-referencing all the vendors it knows about; downloading and creating the Design objects as it goes. 

Reload the [waves page][hand], and there will now be some entries!

[hand]: http://localhost:8080/u/1F44B

---

Now that we have an understanding of our application, let's get it on the cloud. 

---

Next step: [Setup Google Cloud Platform environment](10-setup-gcp.md)
 
 
