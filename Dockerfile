FROM node:0.10-onbuild
MAINTAINER Octoblu <docker@octoblu.com>

EXPOSE 80

RUN curl --silent -L https://github.com/coreos/fleet/releases/download/v0.10.2/fleet-v0.10.2-linux-amd64.tar.gz | tar -xz -C /opt/
ENV PATH $PATH:/opt/fleet-v0.10.2-linux-amd64
