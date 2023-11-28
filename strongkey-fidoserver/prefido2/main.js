/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */

const https = require('https');
var fs = require("fs");
var helmet = require("helmet");
var express = require("express");
var session = require('express-session')
const app = express();
var routes = require('./routes');
const bodyParser = require('body-parser');

//setting certificate info
const options = {
  key: fs.readFileSync("./ssl/key.pem"),
  cert: fs.readFileSync("./ssl/certificate.pem")
};

//setting http headers
app.use(helmet());

app.use(bodyParser.urlencoded({ extended: false }));
app.set('trust proxy', 1) // trust first proxy

//setting session settings
app.use(session({
  secret: 'my-secret',
  resave: false,
  saveUninitialized: true,
  cookie: { maxAge: false }
}))

//setting hostname and ports
const hostname = '127.0.0.1';
const port = 3000;
const sslport = 3001;

//diverting all request traffice to routes.js
app.use('/', routes);

//starting server
app.listen(port);
https.createServer(options, app).listen(sslport,() => console.log(`App listening on port ${sslport}!`));
module.exports = app;
