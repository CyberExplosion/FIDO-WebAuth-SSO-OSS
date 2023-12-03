const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const session = require('express-session');
const https = require('https')
const fs = require('fs')
const Keycloak = require('keycloak-connect');

process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

const app = express();
const memoryStore = new session.MemoryStore();

// Keycloak configuration
const kcConfig = {
  "realm": "passwordless",
  "auth-server-url": "https://localhost:8443/",
  "ssl-required": "external",
  "resource": "websiteapp",
  "credentials": {
    "secret": "5XKp2n7NSo082L2CvKtyg2jbIXR0JgUw"
  },
  "confidential-port": 0
};

const keycloak = new Keycloak({
  store: memoryStore // You can also use a persistent store like Redis for sessions
});

app.use(session({
  secret: '123456789', // Replace with a secure secret key
  resave: false,
  saveUninitialized: true,
}));

app.use(keycloak.middleware());

// Proxy requests to Next.js app
app.use('/', keycloak.protect(), createProxyMiddleware({ target: 'https://localhost:3002', changeOrigin: true, secure: false }));

// app.get('https://localhost:3002', keycloak.protect(), (req, res) => res.send('helloworld'))
const privateKey = fs.readFileSync('./online-study-website/certificates/localhost-key.pem', 'utf-8')
const certificate = fs.readFileSync('./online-study-website/certificates/localhost.pem', 'utf-8')
const cred = { key: privateKey, cert: certificate }
const httpsServer = https.createServer(cred, app)

// Other routes or middleware for your Express server

const PORT = process.env.PORT || 3003;
httpsServer.listen(PORT, () => {
  console.log(`Express server is running on https://localhost:${PORT}`);
});
