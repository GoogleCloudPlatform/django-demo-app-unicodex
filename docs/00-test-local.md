
# Try the application locally

Before you get to deploying this application on Google Cloud, you can test the application locally with Docker, and using Docker Compose. 

You will need to install: 

 * Docker
  * for Windows or macOS: use [Docker Desktop](https://www.docker.com/products/docker-desktop) 
  * for Linux: use [Docker CE](https://docs.docker.com/install/) ([Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/), [Debian](https://docs.docker.com/install/linux/docker-ce/debian/), [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/), and [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/) have dedicated instructions)
 * [Docker Compose](https://docs.docker.com/compose/install/#install-compose)

## Get a local copy of the code

If you are familiar with `git`: 

```
git clone git@github.com:USER/unicodex
cd unicodex
```

Otherwise, you can download and extract the latest [release](https://github.com/USER/unicodex/releases).


## Build the images
 
Before we can run the images, they need to be built. We obtained the instructions that Docker needs for this in the last step.

To build the images: 

```
docker-compose build
``` 

There will now be two images: a `web` container, and a `db` container. 


## Initalize the database

At the moment the database is empty. We can use standard django commands to run our database migrations, add some starting data, and create our admin user; but these instructions need to be run the context of Docker: 

```
docker-compose run --rm web python manage.py migrate
docker-compose run --rm web python manage.py loaddata sampledata
docker-compose run --rm web python manage.py automatesuperuser --username admin --password mysecretadminpassword
```

<small>Tip: `docker-compose run --rm` is quite long. You could create an alias for this command in your `.bashrc`. For example: `alias drc=docker-compose run --rm`. Adjust for your choice of terminal.</small>

<small>We use `automatesuperuser`, which is a modified version of `createsupseruser`, due to `createsuperuser` not being very script-happy. This is used later in our setup scripts</small>


## Start the services

Now we have a database with data, and a build web image, we can start them: 

```
docker-compose up
``` 

You can now see unicodex running in your browser at [http://0.0.0.0:8080/](http://0.0.0.0:8080/)

## 👋

If you've loaded the sample data correctly, you'll have a display that shows the Waving emoji

Clicking on the emoji shows the designs for that emoji. 

Of which, currently, there are none. 

That's okay, we'll add some. 

Go to the [django admin](http://0.0.0.0:8080/admin) and login with the username and password you set up in `automatesuperuser`. 

From there, click on the "Codepoint" model. You should see one listing, `1F44B`. 

Now, click the checkbox on the far left side, and in the Action dropdown, select 'Generate designs for available version versions'. 

Your `docker-compose` window will show a lot of output. What this [admin action](https://docs.djangoproject.com/en/2.2/ref/contrib/admin/actions/) is doing is getting the Emojipedia page for ["waving hand sign"](https://emojipedia.org/waving-hand-sign/), and cross-referencing all the vendors it knows about; downloading and creating the Design objects as it goes. 

Reload the [waves page](http://0.0.0.0:8080/u/1F44B), and there will now be some entries!

---

Now that we have an understanding of our application, let's get it on the cloud. 

---

Next step: [Setup Google Cloud Platform environment](/doc10-setup-gcp.md)
 
 