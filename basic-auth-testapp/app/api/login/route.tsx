import { NextRequest, NextResponse } from "next/server";
// Needed fro the base64url-encoded webapi only accepts
import { create } from "@github/webauthn-json/browser-ponyfill";

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

// Initialize webauthn login
export async function POST (request: NextRequest) {
    const requestBody = await request.json()
    console.log(`The request body is`)
    console.table(requestBody)

    const encodedBody = await create(requestBody)
    console.log(`The encoded body is`)
    console.table(encodedBody)

    const initRes = await fetch(`${hankoApi}/webauthn/login/initialize`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: encodedBody as unknown as BodyInit
    })

    console.log('Message received from hanko')
    console.table(initRes)
    
    const initJson = await initRes.json()

    return NextResponse.json({initJson}, {status: 200})
}