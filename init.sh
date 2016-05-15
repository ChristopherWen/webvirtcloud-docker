#! /bin/bash

if [ -z $DB_ENV_POSTGRES_USER ]; then
    USERNAME=postgres
else
    USERNAME=$DB_ENV_POSTGRES_USER
fi

if [ -n $DB_ENV_POSTGRES_PASSWORD ]; then
    PASSWORD=$DB_ENV_POSTGRES_PASSWORD
elif [ -n $DB_PASSWORD ]; then
    PASSWORD=$DB_PASSWORD
else
    echo "You need set env DB_PASSWORD"
    exit 1
fi

# update password field in setttings.py


# create database
psql -v ON_ERROR_STOP=1 -d postgres://$USERNAME:$PASSWORD@db <<-EOSQL
    CREATE USER wvc WITH PASSWORD '${PASSWORD}';
    CREATE DATABASE wvc;
    GRANT ALL PRIVILEGES ON DATABASE wvc TO wvc;
EOSQL

cd /srv/webvirtcloud
source venv/bin/activate

# update gunicorn configuration
sed -i 's/127.0.0.1/0.0.0.0/g' gunicorn.conf.py

# Another bug in migration "0002" of App logs.
# I worked out a workaround
sed -i 's/AddField/AlterField/g' logs/migrations/0002_auto_20150316_1420.py

# due some bug in Django 1.8. We must run "migrate auth" first otherwise
# contenttypes will failed sometime when try to migration.
python manage.py migrate auth

python manage.py migrate
