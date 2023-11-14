import { NextRequest, NextResponse } from "next/server";

const hankoAdmin = process.env.NEXT_PUBLIC_HANKO_ADMIN_URL

// Handle the browser preflight options
export async function GET (request: NextRequest) {
    const searchParams = request.nextUrl.searchParams
    const userId = searchParams.get('uid')
    console.log(`The user id is: ${userId}`)

    if (userId) {
        console.log(`The user ${userId} exist`)
        const userJsonRes = await fetch(`${hankoAdmin}/users/${userId}`, {
            method: 'GET'
        })
        const userJson = await userJsonRes.json()

        return NextResponse.json({ userJson }, {
            status: 200
        })
    }


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

    return new Response(JSON.stringify({ message: res }), {
        status: 200
    })
}

export async function POST (request: Request) {
    const createUserBody = {
        emails: [
            {
                address: "lo@gmail.com",
                is_primary: true,
                is_verified: true
            }
        ]
    }

    const requestOption: RequestInit = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        credentials: "include",
        mode: "same-origin",
        body: JSON.stringify(createUserBody)
    }
    console.log('The request option is')
    console.table(requestOption.headers)

    const makeUser = await fetch(`${hankoAdmin}/users`, requestOption)
    const setCookieHeader = makeUser.headers.getSetCookie()
    console.log(`THIS IS COOKIE: ${setCookieHeader}`)

    makeUser.headers.forEach((val, key) => {
        console.log(`${key}: ${val}`)
    })


    const res = await makeUser.json()
    console.log(`The result of making new user`)
    console.table(res)

    return new Response(JSON.stringify({ message: `The result is: ${res.message}` }), {
        status: 200
    })
}