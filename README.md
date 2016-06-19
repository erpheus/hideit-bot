# Hide It Bot

This bot will hide the content of a message by replacing non-blank characters with black blocks, also adding a button underneath the message to reveal the content.

### Possible usages

* Sending a book/series/movie spoiler in a group chat so only those users who choose to see it get potentially spoiled.
* Sending a message to someone in wich the text in the notification will be hidden (useful if you fear someone is looking at their screen and maybe reading their notifications).

### How to use it:

Use it inline starting your message with @hideitBot

## Development

You can try to run the code for this bot directly but I suggest you use docker, concretely docker-composer. To install docker and docker-composer go to: (docker compose installation guide)[https://docs.docker.com/compose/install/].

#### Set up

The only thing you need to get started is to create a *tokens.env* file. A good way to create one is to copy *tokens.env.sample* and replace the fields inside. 

Parameters in *tokens.env*:

	* `TELEGRAM_TOKEN`: (mandatory) The token given by telegram for your bot (ask (@botfather)[https://telegram.me/botfather] for one)
	* `BOTAN_TOKEN`: (optional) If you want to use (botan)[http://botan.io/] for traking your users place here your token.
	* `WEBHOOK_DOMAIN`: (optional) If you are going to use the bot with webhooks you have to specify the domain the bot will be running in. See (webhooks section)[#webhooks] for more details.

#### Running with docker

	You can launch the dockerized bot with just one command. This will launch the database first and then the bot and connect them together.

	`docker-compose up --build`

	Refer to the (docker-compose command documentation)[https://docs.docker.com/compose/reference/up/] for more options.

	In case you want to change the command you want to run or see *stdout* in the terminal try running `docker-compose build bot` and `docker-compose run -it bot`

#### Running manually

	First you need to have a functionning mongodb installation accessible at the url *mongodb* (try modifying *etc/hosts*), without password.

	Then you need all of the ruby dependencies: `bundle install`

	After you can run the bot if at the root directory you run the command `ruby src/long_polling.rb`, or `puma -b tcp://0.0.0.0:80 src/server.ru`.

#### Production

	For running in a server there is a different *docker-compose* file called *docker-compose-prod.yml*. By default it will use webhooks. You can run all the docker commands mentioned before but adding `-f docker-compose-prod.yml` just after `docker-compose` in every command.

#### Webhooks

	The server this bot will create doesn't handle the https connections needed for telegram. You should put this bot behind a proxy that will handle that. What the bot will do is generating a token (placed in the bot's url) that will be sent to telegram upon startup, activating webhooks (in case they were not) at the same time.

	Here is a sample vhost configuration file for apache2 that will provide the bot endpoint with authentication for telegram. The certificates have been obtained via (let's encrypt)[http://letsencrypt.org/].

```
<IfModule mod_ssl.c>
Listen 88
<VirtualHost *:88 >
        ServerName example.com
        ProxyPreserveHost On
        ProxyPass / http://localhost:8801/
        ProxyPassReverse / http://localhost:8801
        SSLEngine On
        SSLCertificateFile /etc/letsencrypt/path/to/cert.pem
        SSLCertificateKeyFile /etc/letsencrypt/path/to/privkey.pem
        SSLCertificateChainFile /etc/letsencrypt/path/to/chain.pem
        Include /etc/letsencrypt/options-ssl-apache.conf
        <Location \>
                SSLRequireSSL On
                SSLVerifyClient optional
                SSLVerifyDepth 1
                SSLOptions +StdEnvVars +StrictRequire
        </Location>
        ErrorLog "/var/log/apache2/telegram-error.log"
        CustomLog "/var/log/apache2/telegram-access.log" common
</VirtualHost>

</IfModule>
```

In this case I have used the dafult port for the bot (which is 8801 and can be changed in *docker-compose-prod.yml*) and port 88 as outside port. If you try to do this too you should specify the port 88 in the domain name in *tokens.env*.




