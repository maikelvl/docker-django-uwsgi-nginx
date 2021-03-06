FROM crobays/django-uwsgi:1.1.0
MAINTAINER Crobays <crobays@userex.nl>

ENV DOCKER_NAME django-uwsgi-nginx

RUN add-apt-repository -y ppa:nginx/stable && \
	apt-get update && \
	apt-get -y dist-upgrade && \
	apt-get install -y software-properties-common && \
	apt-get update

RUN apt-get install -y \
	nginx

ENV NGINX_CONF nginx-virtual.conf

# HTTP ports
EXPOSE 80 443

ADD /scripts/nginx-config.sh /etc/my_init.d/06-nginx-config.sh

RUN rm -rf /etc/service/runsv
RUN mkdir /etc/service/nginx && echo "#!/bin/bash\nnginx" > /etc/service/nginx/run

RUN chmod +x /etc/my_init.d/* && chmod +x /etc/service/*/run

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD /conf /conf

