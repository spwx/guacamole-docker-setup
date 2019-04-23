# Scripts to setup guacamole with docker

This script will do all the setup of guacamole and postgresql to get your
own guacamole server setup.

# Usage

1. Install docker
2. git clone https://github.com/spwx/guacamole-docker-setup
3. cd guacamole-docker-setup
2. Edit the top part of setup.sh
4. bash setup.sh

## Nginx

If you are using Nginx as a reverse proxy, add the bellow to the server block
for your site:

```nginx
        location /PATH_TO_GUACAMOLE/ {
            proxy_pass http://HOSTNAME_OR_IP:8080/guacamole/;
            proxy_buffering off;
            proxy_http_version 1.1;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection $http_connection;
            proxy_cookie_path /guacamole/ /PATH_TO_GUACAMOLE/;
            access_log off;
        }
```
