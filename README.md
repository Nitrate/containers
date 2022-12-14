# Welcome to Nitrate Containers

Nitrate is a full-featured test plan, test run and test case
management system, which is written in Python and Django web
framework.

Related Links:

- Documentation: <https://nitrate.readthedocs.io/>
- Source of Nitrate: <https://github.com/Nitrate/Nitrate/>
- Source of containers: <https://github.com/Nitrate/containers/>
- Issues: <https://github.com/Nitrate/Nitrate/issues/>

## Images

Nitrate container images will be built into three separate images:

- `base`: a base image including installed Nitrate inside a
  provisioned virtual environment.
- `web`: a frontend based on the base image to run Nitrate Web
  application.
- `worker`: a backend based on the base image to run asynchronous
  tasks in a Celery worker.

For a regular release, a specific version like `4.12` is applied to
every component image, for example:

- `quay.io/nitrate/base:4.12`
- `quay.io/nitrate/web:4.12`
- `quay.io/nitrate/worker:4.12`

To list tags from command line:

- `make images-overview [version=<version>]`

## Development version of images

Development version of images are built from `develop` branch, which
follow the latest development. The built images always have tags:

- `quay.io/nitrate/base:develop`
- `quay.io/nitrate/web:develop`
- `quay.io/nitrate/worker:develop`

## Worker Image

Nitrate supports to schedule asynchronous tasks as Celery tasks. To
launch a worker container for runnign the asynchronous tasks, a broker
has to be deployed and configured properly so that tasks can be
scheduled and delivered to the worker. Generally, a messaging bus
supporting AMQP is a good choice to be a broker between the Web
frontend and workers.

Please note that, Nitrate is able to run without a worker running in
the backend.

## Make Images

- Make all images: `make all-images`
- Make single component image: `make base-image`, `make web-image`,
  `make worker-image`

The image can be customized by passing various variables:

- `engine`: images are built by podman by default. `docker` can be
  specified when necessary.
- `version`: build image for this specific version.
- `baseimage`: use this image as the base image to build images.
- `ns`: namespace in the registry.

Examples:

- Build frontend for version 4.12: `make web-image version=4.12`
- Build all images and push to registry: `make all-images push-images version=4.12`
- Use newer Fedora release: `make base-image baseimage=registry.fedoraproject.org/fedora:37`
- Build and push to my own organization on registry: `make all-images push-all ns=registry/my-own`
- Use `docker` to build: `make base-image engine=docker`

## Usage

There are built images for every release, which are also pushed to
`quay.io/nitrate` organization. You can pull Nitrate from there and
run it in your favourite container envrionment. Meanwhile, it is also
free to customize and build images by yourself according to your own
requirement.

### Run in local

There are several ways to run Nitrate in local.

Run directly and link the frontend and a database:

```bash
podman run -p 8080:8080 -t quay.io/nitrate/web:4.12
```

As forementioned, launch by compose: `podman-compose up`

### Run in the cloud

To deploy Nitrate in the could, please refer to the documentation of
the specific cloud product.

In case you are using the OpenShift, please move to
<https://docs.openshift.com/>.

In whatever the way you run the Nitrate in the cloud, the environment
variables and volumes described below may be used to customize the
use and maintenance.

## Environment Variables

`NITRATE_DB_*`: There are a few of environment variables you can set
  to configure for the database connection from the Web container:

- `NITRATE_DB_ENGINE`: set to use which database backend. It could be
  `mysql` or `pgsql`.
- `NITRATE_DB_NAME`: the database name to connect. This is
  optional. Default to `nitrate`.
- `NITRATE_DB_USER`: the username used to connect to database. This is
  optional. Default to `nitrate`.
- `NITRATE_DB_PASSWORD`: the password used with username together to
  connect a database. This is optional. Without passing a password,
  empty password is used to connect the database. Hence, it depends on
  the authentication configuration in database server side whether to
  allow logging in with empty password.
- `NITRATE_DB_HOST`: the host name of database server. This is
  optional. Default to connect to localhost. Generally, this variable
  must be set at least.
- `NITRATE_DB_PORT`: the database port to connect. This is
  optional. Default to the database default port. Please consult the
  concrete database product documentation. Generally, default port of
  MySQL and MariaDB is `3306`, and PostgreSQL's is `5432`.

`NITRATE_MIGRATE_DB`: This variable is optional and allows to run the
database migrations during launching the container. This is useful
particularly for the first time to run Nitrate.

`NITRATE_SUPERUSER_USERNAME`, `NITRATE_SUPERUSER_PASSWORD`,
`NITRATE_SUPERUSER_EMAIL`: These variables are optional to create a
superuser account during launching the container. All of these three
variables must be set at the same time. This is helpful for the first
time to run Nitrate in order to login quickly just after the container
is launched successfully.

`NITRATE_SET_DEFAULT_PERMS`: This variable is optional to create the
default groups and grant permissions to them.

## Volumes

`/var/log/httpd`: The directory to store the httpd log files. Ensure
the write permission is granted properly.

`/project/uploads`: The directory to store the uploaded attachment
files. Ensure the write permission is granted properly.

`/project/nitrate-config`: The directory holding the custom config
module. Mount this volume when default settings have to be
customized. For most of the cases running Nitrate in your cloud
environment, customization should be required. To customize the
settings, create a Python module `nitrate_custom_conf.py` inside a
directory which will be mounted to this container volume.

## Report Issues

Report issue here <https://github.com/Nitrate/Nitrate/issues/new>

## Sign-off commit

Every commit must be signed off. This can be done by specifying option
`-s` to `git commit`, for example:

```bash
git commit -s -m "commit message"
```

The sign-off means you have read and agreed to [Developer Certificate
of Origin](https://developercertificate.org/):

```plain
Developer Certificate of Origin
Version 1.1

Copyright (C) 2004, 2006 The Linux Foundation and its contributors.

Everyone is permitted to copy and distribute verbatim copies of this
license document, but changing it is not allowed.


Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

(a) The contribution was created in whole or in part by me and I
    have the right to submit it under the open source license
    indicated in the file; or

(b) The contribution is based upon previous work that, to the best
    of my knowledge, is covered under an appropriate open source
    license and I have the right under that license to submit that
    work with modifications, whether created in whole or in part
    by me, under the same open source license (unless I am
    permitted to submit under a different license), as indicated
    in the file; or

(c) The contribution was provided directly to me by some other
    person who certified (a), (b) or (c) and I have not modified
    it.

(d) I understand and agree that this project and the contribution
    are public and that a record of the contribution (including all
    personal information I submit with it, including my sign-off) is
    maintained indefinitely and may be redistributed consistent with
    this project or the open source license(s) involved.
```
