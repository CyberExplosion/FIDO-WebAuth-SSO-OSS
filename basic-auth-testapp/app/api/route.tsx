import { NextResponse } from "next/server";

const hankoAdmin = process.env.NEXT_PUBLIC_HANKO_ADMIN_URL

// Handle the browser preflight options
export async function GET (request: Request) {
    const jsonRes = await fetch(`${hankoAdmin}/users`,
        {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            },
        })
    const res = await jsonRes.json()

    console.log('The result is')
    console.table(res)

    return new Response('From, Next.js api route', {
        status: 200,
        headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
    })
}

export async function POST (request: Request) {
    const createUserBody = {
        emails: [
            {
                address: "cyberhyperwave@gmail.com",
                is_primary: true
            }
        ]
    }

    const makeUser = await fetch(`${hankoAdmin}/users`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(createUserBody)
    })

    const res = await makeUser.json()

    console.log(`The result of making new user`)
    console.table(res)

    return new Response(`The user is ${res}`, {
        status: 200
    })
}