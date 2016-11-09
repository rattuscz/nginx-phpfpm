#!/bin/sh

if [ -z "$SSL_IGNORE_CA_CERT" ] && [ -z "$SSL_CLIENT_CA_CERT" ]; then
    echo "ENV variable SSL_CLIENT_CA_CERT is missing, set with value from \"awk 1 ORS='\\n' ca-public-cert.pem\"" >&2
    exit 3
fi

if [ -z "$SSL_CERT" ]; then
    echo "ENV variable SSL_CERT is missing, set with with value from \"awk 1 ORS='\\n' web-ssl-cert.pem\"" >&2
    exit 4
fi

if [ -z "$SSL_KEY" ]; then
    echo "ENV variable SSL_KEY is missing, set with with value from \"awk 1 ORS='\\n' web-ssl-pkey.pem\"" >&2
    exit 5
fi

if [ -z "$SSL_DH" ]; then
    echo "ENV variable SSL_DH is missing, generate DHE with 'openssl dhparam -out dhparam.pem 4096' and set with with value from \"awk 1 ORS='\\n' dhparam.pem\"" >&2
    exit 6
fi

if [ -z "$SSL_IGNORE_CA_CERT" ]; then
	# create client ssl cert file, ensure config is not commented
	echo $SSL_CLIENT_CA_CERT |  sed 's/\\n/\n/g' > /etc/nginx/ssl/ssl-client-ca-cert.pem
	sed -i 's/#*ssl_verify_client/ssl_verify_client/' /etc/nginx/sites-available/default
	sed -i 's/#*ssl_client_certificate/ssl_client_certificate/' /etc/nginx/sites-available/default
else
	# comment out client ssl parts
	sed -i 's/#*ssl_verify_client/#ssl_verify_client/' /etc/nginx/sites-available/default
	sed -i 's/#*ssl_client_certificate/#ssl_client_certificate/' /etc/nginx/sites-available/default
fi

echo $SSL_CERT | sed 's/\\n/\n/g' > /etc/nginx/ssl/ssl-cert.pem
echo $SSL_KEY  | sed 's/\\n/\n/g' > /etc/nginx/ssl/ssl-cert-pkey.pem
echo $SSL_DH   | sed 's/\\n/\n/g' > /etc/nginx/ssl/dhparam.pem

exit 0