const express = require('express')
const fs = require('fs')
const https = require('https')
const bodyParser = require('body-parser')
const jwt = require('jsonwebtoken');
const base64url = require('base64url');


process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

const PORT = 3030
const filePath = './response.json'

const app = express()
app.use(express.json())

// // Your route handling
// app.post('/', (req, res) => {
//     let arrayBufferData = '';
//
//     req.on('data', (chunk) => {
//         arrayBufferData += chunk;
//     });
//
//     req.on('end', () => {
//         try {
//             console.log(`Raw data: ${arrayBufferData}`)
//
//             console.log('Decode the jwt')
//             // const rawData = arrayBufferData.toString()
//             const decoded = jwt.verify(arrayBufferData, 'v2vwWZbJGgrd3f3CSwoUvBLkq5TQZnnDZId1B5L2Uk4', {complete: true})
//
//
//             // Now you can work with the decoded data
//             console.log(decoded);
//             console.table(decoded)
//
//             res.status(200).json({ success: true });
//         } catch (error) {
//             console.error('Error handling ArrayBuffer data:', error);
//             res.status(400).json({ error: 'Invalid data format' });
//         }
//     });
// });

app.post('/', (req, res) => {
    console.log('CAS saving new clients')
    console.log(req.body)

    res.status(200).send()
})

app.delete('/', (req, res) => {
    console.log('CAS request to delete')
    console.log(req.body)

    res.status(200).send()
})

app.get('/', (req, res) => {
    try {
        const file = fs.readFileSync('./clients.json', 'utf-8')
        const jsonParse = JSON.parse(file)
        console.log(`The json file is`)
        console.log(JSON.stringify(jsonParse, null, 2))

        const bodyData = req.body
        if (Object.keys(bodyData).length === 0) {
            res.status(200).json(jsonParse)
        }
        else {
            console.log(`CAS attemped to use FindByID`)
            res.status(501).json({msg: 'Server not figure out what to deal with this'})
        }
    }
    catch (err) {
        console.error(`Error: ${err}`)
        res.status(500).send()
    }
})

const key = fs.readFileSync('./certificates/localhost-key.pem', 'utf-8')
const cert = fs.readFileSync('./certificates/localhost.pem', 'utf-8')
const credentials = { key: key, cert: cert }

const httpsServer = https.createServer(credentials, app)

httpsServer.listen(PORT, () => {
    console.log(`The server is listening on: https://localhost:${PORT}`)
})