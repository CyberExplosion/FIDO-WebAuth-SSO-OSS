import { NextRequest } from "next/server"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

export async function POST (request: NextRequest) {
    const response = await fetch(`${hankoApi}/token`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: await request.json()
    })
    const responseJson = await response.json()

    console.log(`The JWT response`)
    console.table(responseJson)
}