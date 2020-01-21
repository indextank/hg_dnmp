FROM phusion/baseimage:latest

LABEL maintainer="Mahmoud Zalt <mahmoud@zalt.me>"

COPY run-certbot.sh /opt/run-certbot.sh

RUN chmod +x /opt/run-certbot.sh \
    && apt-get update \
    && apt-get install -y letsencrypt

ENTRYPOINT bash -c "bash /opt/run-certbot.sh 2>&1 | tee -a /var/www/html/run_certbot.log && sleep infinity"