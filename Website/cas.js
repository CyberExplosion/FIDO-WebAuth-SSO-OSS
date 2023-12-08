const https = require('https')
const httpCasClient = require('http-cas-client')
const fs = require('fs')
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

const PORT = 3002;
const CAS = 'https://localhost:8443/cas'
const redirect = 'https://localhost:3003'

const handler = httpCasClient({
    casServerUrlPrefix: CAS,
    serverName: `https://localhost:${PORT}/cas`
})

const privateKey = fs.readFileSync('./online-study-website/certificates/localhost-key.pem', 'utf-8')
const certificate = fs.readFileSync('./online-study-website/certificates/localhost.pem', 'utf-8')
const cred = { key: privateKey, cert: certificate }

const httpsServer = https.createServer(cred, async (req, res) => {
    if (!await handler(req, res)) {
        return res.end();
    }

    const { principal, ticket } = req;
    console.log(principal, ticket);
    // { user: 'test', attributes: { ... } }

    // your statements...
    res.writeHead(302, {location: redirect})
    res.end('hello world');
})

httpsServer.listen(PORT, () => {
  console.log(`Express server is running on https://localhost:${PORT}/cas`);
});