# For the APPSERVER

FROM ubuntu:latest

RUN apt-get update

RUN apt install -y nodejs npm sqlite

COPY ./ /postfido2

WORKDIR /postfido2

RUN npm install

RUN npm install pm2@latest -g

RUN npm install express-useragent

RUN pm2 start main.js

RUN pm2 startup systemd

RUN pm2 save

# Start the nodejs app
CMD ["node", "main.js"]