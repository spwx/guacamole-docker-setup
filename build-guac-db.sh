####### Build the postgres docker image

# make a directory to build the postgres image
mkdir guac-pg
cd guac-pg

# generate the initdb.sql script
sudo docker run --rm guacamole/guacamole \
    /opt/guacamole/bin/initdb.sh --postgres > initdb.sql

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

# build the postgres image setup for guacamole
sudo docker build . --tag guac-pg

#clean up
cd ..
rm -rf guac-pg
