#!/bin/bash

set -e

################################## EDIT THIS ##################################
# PostgreSQL admin account:
export pg_user=postgres
export pg_password=guacamole

# PostgreSQL account to be used by guacamole:
export guac_user=guacamole
export guac_password=guacamole

# Change this to the IP address your reverse proxy, if you have one
export ip="127.0.0.1"
###############################################################################


bash build-guac-db.sh
bash build-guac-rp.sh


# run the docker containers, and restart them after a reboot
sudo docker run --restart unless-stopped --name guac-pg -d guac-pg \
    -v guac-data:/var/lib/postgres/data
sudo docker run --restart unless-stopped --name guacd -d guacamole/guacd

sudo docker run --restart unless-stopped --name guacamole-rp \
    --link guacd:guacd \
    --link guac-pg:postgres \
    -e POSTGRES_DATABASE=guacamole_db \
    -e POSTGRES_PASSWORD=guacamole \
    -e POSTGRES_USER=guacamole \
    -d -p 8080:8080 guacamole-rp
