# nginx-php5
Includes nginx, phpfpm, php5, cron and certbot ([Lets encrypt](https://certbot.eff.org/#debianjessie-nginx)) running with supervisor

## To build

```
$ sudo docker build -t yourname/nginx-php .
```
## To run

Nginx will look for files in /var/html/www so you need to map your application to that directory.

Let's encrypt can be used for SSL certificates using ENVs. Certificates will be stored on /data/letsencrypt
- **SSL_USE_LETSENCRYPT** - Nonempty value will trigger using letsencrypt certbot for certificates retrieval
- **LE_EMAIL** - Lets encrypt registration email
- **LE_DOMAIN** - Primary domain ( used in nginx config to locate certificate )
- **LE_DOMAINS** - **Optional**, Lets encrypt domain list for certificate, comma separated. If not provided will be equal to LE_DOMAIN

If not using Lets encrypt, SSL requires ssl certificate passed in ENV variables, you need to provide those:
- **SSL_CERT** - Server SSL certificate - you can generate this string from ```awk 1 ORS='\\n' web-ssl-cert.pem```
- **SSL_KEY** - Server SSL certificate private key - can be obtained by running ```awk 1 ORS='\\n' web-ssl-pkey.pem```
- **SSL_DH** - Diffie-Hellman parameters - you can generate file with ```openssl dhparam -out dh.pem 4096``` and use this value ```awk 1 ORS='\\n' dhparam.pem```

For client authentication following ENV variables are used
- **SSL_IGNORE_CA_CERT** - If not empty the client certification will not be required and will not be used by nginx
- **SSL_CLIENT_CA_CERT** - CA public certificate for client certification validation

```
sudo docker run -d -p 8000:80 --volumes-from APPDATA -v /home/me/myphpapp:/var/html/www --name lemp yourname/nginx-php
```

The --volumes-from argument means that you're using a Data-only container pattern.

If you want to link the container to a Postgres contaier do:

```
sudo docker run -d -p 8000:80 --volumes-from APPDATA -v /home/me/myphpapp:/var/html/www --name lemp postgres-container:pg yourname/nginx-php
```

All ENV variables are passed to PHP, with SSL client certificate values added from nginx:

- **SSL_C_VERIFIED** $ssl_client_verify;
- **SSL_C_DN**   $ssl_client_s_dn;
- **SSL_C_SN**   $ssl_client_serial;
- **SSL_C_CERT** $ssl_client_raw_cert;

### Credits
	- Credit to: Nian Wang
	- Original work can be found at: https://github.com/nianwang/docker-index

	- Credit to: Luis Elizondo
	- Original work can be found at: https://github.com/iiiepe/nginx-php

### License
The original author didn't relase the code with a License. But this code is released under the MIT License.


