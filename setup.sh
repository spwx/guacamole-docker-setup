#!/bin/bash

set -e

################################## EDIT THIS ##################################
# PostgreSQL admin account:
pg_user=postgres
pg_password=guacamole

# PostgreSQL account to be used by guacamole:
guac_user=guacamole
guac_password=guacamole

# Change this to the IP address your reverse proxy, if you have one
ip="127.0.0.1"
###############################################################################

# make a directory to build the postgres image
mkdir guac-db

# make a directory to build the guacamole image
mkdir guacamole

# generate the initdb.sql script
sudo docker run --rm guacamole/guacamole \
    /opt/guacamole/bin/initdb.sh --postgres > guac-db/initdb.sql

# append guacamole user creation to initdb.sql
cat <<EOT >> guacd-db/initdb.sql


CREATE USER $guac_user WITH PASSWORD '$guac_password';
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO $guac_user;
GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO $guac_user;
EOT


# create a Dockerfile which extends postgres with the initdb.sql script
#
# anything placed into the /docker-entrypoint-initdb.d/ directory will be run
# automatically when the container starts
cat <<EOT >> guac-db/Dockerfile
FROM postgres
ENV POSTGRES_DB guacamole_db
ENV POSTGRES_USER $pg_user
ENV POSTGRES_PASSWORD $pg_password
COPY initdb.sql /docker-entrypoint-initdb.d/
EOT

# Create a docker volume to store the database data
sudo docker volume create guac-data

# run the docker containers, and restart them after a reboot
sudo docker build guac-db --tag guac-pg
sudo docker run --restart unless-stopped --name guac-pg -d guac-pg \
    -v guac-data:/var/lib/postgres/data
sudo docker run --restart unless-stopped --name guacd -d guacamole/guacd

sudo docker run --restart unless-stopped --name guacamole \
    --link guacd:guacd \
    --link guac-pg:postgres \
    -e POSTGRES_DATABASE=guacamole_db \
    -e POSTGRES_PASSWORD=guacamole \
    -e POSTGRES_USER=guacamole \
    -d -p 8080:8080 guacamole/guacamole


# Add this!
# ip="192.168.1.12"

# cat <<EOF > tmp
# <Valve className="org.apache.catalina.valves.RemoteIpValve"
#                internalProxies="$ip"
#                remoteIpHeader="x-forwarded-for"
#                remoteIpProxiesHeader="x-forwarded-by"
#                protocolHeader="x-forwarded-proto" />

# EOF

# # find the line number of the "</Host>" line, and return only the line number
# line=`grep -n '</Host>' server | cut -f1 -d:`
# line=`expr $line - 1`

# sed "${line}r tmp" server
# rm tmp
