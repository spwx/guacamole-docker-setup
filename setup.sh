#!/bin/bash

set -e

# PostgreSQL account to be used by guacamole:
guac_user=guacamole
guac_password=guacamole

# PostgreSQL admin account:
pg_user=postgres
pg_password=guacamole


# generate the initdb.sql script
sudo docker run --rm guacamole/guacamole \
    /opt/guacamole/bin/initdb.sh --postgres > initdb.sql

sudo docker volume create guac-data

# append guacamole user creation to initdb.sql
cat <<EOT >> initdb.sql


CREATE USER $guac_user WITH PASSWORD '$guac_password';
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO $guac_user;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO $guac_user;
EOT

# create a Dockerfile which extends postgres with the initdb.sql script
#
# anything placed into the /docker-entrypoint-initdb.d/ directory will be run
# automatically when the container starts
cat <<EOT >> Dockerfile
FROM postgres
ENV POSTGRES_DB guacamole_db
ENV POSTGRES_USER $pg_user
ENV POSTGRES_PASSWORD $pg_password
COPY initdb.sql /docker-entrypoint-initdb.d/
EOT

# run the docker containers, and restart them after a reboot
sudo docker build . --tag guac-pg
sudo docker run --restart unless-stopped --name guac-pg -d guac-pg
sudo docker run --restart unless-stopped --name guacd -d guacamole/guacd

sudo docker run --restart unless-stopped --name guacamole \
    --link guacd:guacd \
    --link guac-pg:postgres \
    -e POSTGRES_DATABASE=guacamole_db \
    -e POSTGRES_PASSWORD=guacamole \
    -e POSTGRES_USER=guacamole \
    -d -p 8080:8080 guacamole/guacamole
