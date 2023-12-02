import { btoa } from "buffer";
import { NextRequest, NextResponse } from "next/server";

// Allow self-signed certificate
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'
const INTROSPECT = 'https://127.0.0.1:8443/realms/passwordless/protocol/openid-connect/token/introspect'
const APISECRET = process.env.NEXT_PUBLIC_APISECRET
const CLIENTID = 'backend'

export async function POST (request: NextRequest, response: NextResponse) {
    const bodyToken = await request.json()
    // console.log(`The token is ${JSON.stringify(bodyToken, null, 2)}`)
    const basicAuth = btoa(`${CLIENTID}:${APISECRET}`)
    const formData = new URLSearchParams()  // Not type json so cannot use json to fetch
    formData.append('token', bodyToken['token'])

    const ret = await fetch(INTROSPECT, {
        method: "POST",
        headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "Authorization": `Basic ${basicAuth}`
        },
        body: formData.toString()
    })

    const retJson = await ret.json()
    console.log(`Result of fetch: ${JSON.stringify(retJson)}`)
    
    const secretData = {msg: 'Have a nice day!'}
    const badData = {msg: 'Not authorized to access!'}

    if (retJson['active']) {
        console.log('The token is valid')
        return new Response(JSON.stringify(secretData), {
            status: 200,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            }
        })
    } else {
        return new Response(JSON.stringify(badData), {
            status: 403,
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            }
        })
    }

}

// export async function OPTIONS () {
//     return new Response('Hello', {
//         status: 200,
//         headers: {
//             'Access-Control-Allow-Origin': '*',
//             'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
//             'Access-Control-Allow-Headers': 'Content-Type, Authorization',
//         }
//     })
// }