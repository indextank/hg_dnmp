#!/bin/bash

if [ ! -n "${CN}" ] || [ ! -n "${EMAIL}" ]; then
    echo -e '$CN and $EMAIL is empty!~~~\n\n\n'
else
    letsencrypt certonly --webroot -w /var/www/letsencrypt -d "$CN" --agree-tos --email "$EMAIL" --non-interactive --text

    cp /etc/letsencrypt/archive/"$CN"/cert1.pem /var/certs/cert1.pem
    cp /etc/letsencrypt/archive/"$CN"/privkey1.pem /var/certs/privkey1.pem
fi