FROM node:0.10-onbuild
MAINTAINER Octoblu <docker@octoblu.com>

EXPOSE 80

RUN curl --silent -L https://cdn.octoblu.com/fleet/fleet-linux-amd64.tar.gz | tar -xz -C /opt/
ENV PATH $PATH:/opt/fleet-linux-amd64
