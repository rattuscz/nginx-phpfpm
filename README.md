# nginx-php5
Includes nginx and php5 running with supervisor

## To build

```
$ sudo docker build -t yourname/nginx-php .
```
## To run

Nginx will look for files in /var/html/www so you need to map your application to that directory.

SSL will look for  ssl certificate /data/web_ssl.crt and corresponding private key /data/web_ssl.rsa so you need to map /data directory with those
SSL also uses /data/dh.pem for Diffie-Hellman parameters - you can generate with ```openssl dhparam -out dh.pem 4096```

```
sudo docker run -d -p 8000:80 --volumes-from APPDATA -v /home/me/myphpapp:/var/html/www --name lemp yourname/nginx-php
```

The --volumes-from argument means that you're using a Data-only container pattern.

If you want to link the container to a Postgres contaier do:

```
sudo docker run -d -p 8000:80 --volumes-from APPDATA -v /home/me/myphpapp:/var/html/www --name lemp postgres-container:pg yourname/nginx-php
```

The startup.sh script will add all the environment variables to /etc/php5/fpm/pool.d/env.conf so PHP-FPM detects them. If you need to use them you can do:
```<?php getenv("SOME_ENV_VARIABLE_THAT_HAS_MYSQL_IN_THE_NAME"); ?>```


### Credits
	- Credit to: Nian Wang
	- Original work can be found at: https://github.com/nianwang/docker-index

	- Credit to: Luis Elizondo
	- Original work can be found at: https://github.com/iiiepe/nginx-php

### License
The original author didn't relase the code with a License. But this code is released under the MIT License.


