#!/bin/sh

if [ -z "$SSL_IGNORE_CA_CERT" ]; then
    if [ -z "$SSL_CLIENT_CA_CERT" ]; then
        echo "[CRIT] ENV variable SSL_CLIENT_CA_CERT is missing, set with value from \"awk 1 ORS='\\\n' ca-public-cert.pem\"" >&2
        exit 103
    fi
	# create client ssl cert file, ensure config is not commented
	echo $SSL_CLIENT_CA_CERT |  sed 's/\\n/\n/g' > /etc/nginx/ssl/ssl-client-ca-cert.pem
	sed -i 's/#*ssl_verify_client/ssl_verify_client/' /etc/nginx/conf.d/default.conf
	sed -i 's/#*ssl_client_certificate/ssl_client_certificate/' /etc/nginx/conf.d/default.conf
else
	# comment out client ssl parts
	sed -i 's/#*ssl_verify_client/#ssl_verify_client/' /etc/nginx/conf.d/default.conf
	sed -i 's/#*ssl_client_certificate/#ssl_client_certificate/' /etc/nginx/conf.d/default.conf
fi

if [ -z "$SSL_DH" ]; then
    echo "[CRIT] ENV variable SSL_DH is missing, generate DHE with 'openssl dhparam -out dhparam.pem 4096' and set with with value from \"awk 1 ORS='\\\n' dhparam.pem\"" >&2
    exit 106
fi
echo $SSL_DH   | sed 's/\\n/\n/g' > /etc/nginx/ssl/dhparam.pem

if [ -z "$SSL_USE_LETSENCRYPT" ]; then
    # use certificates from command line
    if [ -z "$SSL_CERT" ]; then
        echo "[CRIT] ENV variable SSL_CERT is missing, set with with value from \"awk 1 ORS='\\\n' web-ssl-cert.pem\"" >&2
        exit 104
    fi

    if [ -z "$SSL_KEY" ]; then
        echo "[CRIT] ENV variable SSL_KEY is missing, set with with value from \"awk 1 ORS='\\\n' web-ssl-pkey.pem\"" >&2
        exit 105
    fi

    # enable ssl
    sed -i 's/#*ssl_certificate/ssl_certificate/' /etc/nginx/conf.d/default.conf
    sed -i 's/listen 443; #ssl/listen 443 ssl/' /etc/nginx/conf.d/default.conf

    echo $SSL_CERT | sed 's/\\n/\n/g' > /etc/nginx/ssl/ssl-cert.pem
    echo $SSL_KEY  | sed 's/\\n/\n/g' > /etc/nginx/ssl/ssl-cert-pkey.pem
    sed -i 's/ssl_certificate\s[^;]*;/ssl_certificate      \/etc\/nginx\/ssl\/ssl-cert.pem;/' /etc/nginx/conf.d/default.conf
    sed -i 's/ssl_certificate_key\s[^;]*;/ssl_certificate_key  \/etc\/nginx\/ssl\/ssl-cert-pkey.pem;/' /etc/nginx/conf.d/default.conf
else
    # use let's encrypt for certificates
    if [ -z "$LE_EMAIL" ]; then
        echo "[CRIT] ENV variable LE_EMAIL is missing, provide email address for Lets encrypt" >&2
        exit 108
    fi
    if [ -z "$LE_DOMAIN" ]; then
        echo "[CRIT] ENV variable LE_DOMAIN is missing, provide domains to register for Lets encrypt" >&2
        exit 109
    fi
    if [ -z "$LE_DOMAINS" ]; then
        export LE_DOMAINS=$LE_DOMAIN
    fi

    sed -i "s/.*email = .*/email = $LE_EMAIL/" /etc/letsencrypt/cli.ini
    sed -i "s/.*domains = .*/domains = $LE_DOMAINS/" /etc/letsencrypt/cli.ini

    if [ ! -d "/data/letsencrypt/$LE_DOMAIN" ]; then
        # no certificates yet, disable SSL for now
        sed -i 's/#*ssl_certificate/#ssl_certificate/' /etc/nginx/conf.d/default.conf
        sed -i 's/listen 443 ssl/listen 443; #ssl/' /etc/nginx/conf.d/default.conf
        /usr/sbin/nginx -s reload

        # request cert
        certbot certonly -n -q

        # enable ssl
        sed -i 's/#*ssl_certificate/ssl_certificate/' /etc/nginx/conf.d/default.conf
        sed -i 's/listen 443; #ssl/listen 443 ssl/' /etc/nginx/conf.d/default.conf
    fi

    sed -i "s/ssl_certificate\s[^;]*;/ssl_certificate     \/data\/letsencrypt\/live\/$LE_DOMAIN\/fullchain.pem;/" /etc/nginx/conf.d/default.conf
    sed -i "s/ssl_certificate_key\s[^;]*;/ssl_certificate_key \/data\/letsencrypt\/live\/$LE_DOMAIN\/privkey.pem;/" /etc/nginx/conf.d/default.conf

fi

# instruct nginx to reload if already running
/usr/sbin/nginx -s reload
exit 0