#!/bin/bash

DOMAIN_NAME="test.domain.net"

get_cert_date () {
        EXPIRE_DATE=`echo | openssl x509 -noout -dates -in /etc/letsencrypt/live/$1/cert.pem| grep notAfter | cut -d'=' -f2`
        EXPIRE_SECS=`date -d "${EXPIRE_DATE}" +%s`
        EXPIRE_TIME=$(( ${EXPIRE_SECS} - `date +%s` ))
        RETVAL=$(( ${EXPIRE_TIME} / 24 / 3600 ))
        return "${RETVAL}"
}

get_cert_date $DOMAIN_NAME

if [[ $? -lt 30 ]];
then
        /usr/bin/certbot certonly -m  kgm@gmail.com --standalone --preferred-challenges http --http-01-port 54321 -d $DOMAIN_NAME --renew-by-default -n  --agree-tos  >> /var/log/cert_update.log
else
        exit 0
fi

cat /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem > /etc/certs/haproxy_cert.pem

sleep 5

systemctl reload haproxy.service
