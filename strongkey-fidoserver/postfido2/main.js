/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */

import { createServer } from 'https';
import { readFileSync } from "fs";
import helmet from "helmet";
import express from "express";
import session from 'express-session';
const app = express();
import routes from './routes.js';
// import { urlencoded } from 'body-parser';

import pkg from 'body-parser';
const { urlencoded } = pkg;

//setting certificate info
const options = {
  key: readFileSync("./ssl/key.pem"),
  cert: readFileSync("./ssl/certificate.pem")
};

//setting http headers
app.use(helmet());

app.use(urlencoded({ extended: false }));
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
createServer(options, app).listen(sslport,() => console.log(`App listening on port ${sslport}!`));
export default app;
