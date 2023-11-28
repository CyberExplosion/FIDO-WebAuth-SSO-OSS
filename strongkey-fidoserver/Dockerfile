# For the APPSERVER

FROM ubuntu:latest

# This IP
ENV APPSERVER_IP=11.29.215.103

COPY prefido2 /prefido2

RUN apt-get update

RUN apt install -y nodejs npm sqlite

WORKDIR /prefido2

RUN npm install

RUN npm install pm2@latest -g

RUN pm2 start main.js

RUN pm2 startup systemd

RUN pm2 save