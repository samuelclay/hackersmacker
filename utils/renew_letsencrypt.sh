#!/bin/bash

# Path to the letsencrypt-auto tool
LE_TOOL=/srv/certbot-auto

# Directory where the acme client puts the generated certs
LE_OUTPUT=/etc/letsencrypt/live

WEBROOT=/opt/letsencrypt/html

# Concat the requested domains
DOMAINS=""
for DOM in "$@"
do
    DOMAINS+=" -d $DOM -d www.$DOM"
done

# Create or renew certificate for the domain(s) supplied for this tool
$LE_TOOL --agree-tos --renew-by-default certonly --webroot -w=$WEBROOT $DOMAINS
# $LE_TOOL --agree-tos --renew-by-default --standalone --standalone-supported-challenges http-01 --http-01-port 9999 certonly $DOMAINS

# Cat the certificate chain and the private key together for haproxy
cat $LE_OUTPUT/$1/{fullchain.pem,privkey.pem} > /etc/haproxy/certs/${1}.pem

# Reload the haproxy daemon to activate the cert
systemctl reload haproxy