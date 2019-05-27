all: renew
	
renew:
	sudo /etc/init.d/haproxy stop
	sudo letsencrypt renew
	DOMAIN='hackersmacker.org' sudo -E bash -c 'cat /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/letsencrypt/live/$DOMAIN/privkey.pem > /etc/haproxy/certs/$DOMAIN.pem' 
	sudo /etc/init.d/haproxy start
	
