#!/usr/bin/bash -e

django_admin=/project/venv/bin/django-admin

# Wait for database is up
#
script="\
from time import sleep
from django.db import connection
while True:
    try:
        with connection.cursor() as cur:
            cur.execute('SELECT 1')
    except:
        print('Failed to connect to database. Sleep for a while and try again ...')
        sleep(0.7)
    else:
        print('Database seems ready for use now.')
        break
"
"$django_admin" shell -c "$script"

# Migrate database
#
if [ -n "$NITRATE_MIGRATE_DB" ]
then
    echo "Start to migrate database ..."
    "$django_admin" migrate
else
    echo "Environment variable NITRATE_MIGRATE_DB is not set. Skip migrating database."
fi

# Create a superuser account
#
script_user_exists="\
from django.contrib.auth.models import User
exists = User.objects.filter(
    username='admin',
    email='${NITRATE_SUPERUSER_EMAIL}',
    is_superuser=True,
).exists()
print(str(exists).lower())
"
script_create_superuser="\
from django.contrib.auth.models import User
User.objects.create_superuser(
    '${NITRATE_SUPERUSER_USERNAME}',
    email='${NITRATE_SUPERUSER_EMAIL}',
    password='${NITRATE_SUPERUSER_PASSWORD}',
)
"
if [ -z "$NITRATE_SUPERUSER_USERNAME" ] || [ -z "$NITRATE_SUPERUSER_PASSWORD" ] || [ -z "$NITRATE_SUPERUSER_EMAIL" ]
then
    echo "NITRATE_SUPERUSER_USERNAME, NITRATE_SUPERUSER_PASSWORD and NITRATE_SUPERUSER_EMAIL are not set." \
         "Skip creating a superuser."
else
    user_exists=$("$django_admin" shell -c "$script_user_exists")
    if [ "$user_exists" == "true" ]
    then
	echo "Superuser $NITRATE_SUPERUSER_USERNAME has been created."
    else
        echo "Start to create a superuser account for ${NITRATE_SUPERUSER_USERNAME} ..."
	"$django_admin" shell -c "$script_create_superuser"
    fi
fi

# Set default permissions to default groups
#
if [ -n "$NITRATE_SET_DEFAULT_PERMS" ]
then
    "$django_admin" setdefaultperms
    echo "Default groups are created and permissions are set to groups properly."
else
    echo "Environment variable NITRATE_SET_DEFAULT_PERMS is not set."
    echo "Skip creating default groups and granting permissions to specific group."
fi


httpd -D FOREGROUND
