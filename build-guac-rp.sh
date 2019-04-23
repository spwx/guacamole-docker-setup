####### Build the guacamole image for remote proxy

# make a directory to build the guacamole image
mkdir guacamole-rp
cd guacamole-rp

# get a copy of server.conf from the base image
sudo docker run --rm guacamole/guacamole \
    cat /usr/local/tomcat/conf/server.xml > server.xml

cat <<EOF > tmp
        <Valve className="org.apache.catalina.valves.RemoteIpValve"
                       internalProxies="$ip"
                       remoteIpHeader="x-forwarded-for"
                       remoteIpProxiesHeader="x-forwarded-by"
                       protocolHeader="x-forwarded-proto" />

EOF

# find the line number of the "</Host>" line, and return only the line number
line=`grep -n '</Host>' server.xml | cut -f1 -d:`
line=`expr $line - 1`

sed -i "${line}r tmp" server.xml

cat <<EOT > Dockerfile
FROM guacamole/guacamole
COPY server.xml /usr/local/tomcat/conf/server.xml
EOT

# build the postgres image setup for guacamole
sudo docker build . --tag guacamole-rp

cd ..
rm -rf guacamole-rp
