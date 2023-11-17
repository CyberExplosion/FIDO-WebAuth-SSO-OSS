'use client'

import { RegistrationPublicKeyCredential, create, parseCreationOptionsFromJSON } from "@github/webauthn-json/browser-ponyfill"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

// Use x-auth-token instead of cookie to work with chrome not allowing cross-domain cookies
const webauthnInit = async () => {
    const xAuthToken = sessionStorage.getItem('hanko') || ''
    const response = await fetch(`${hankoApi}/webauthn/registration/initialize`, {
        method: 'POST',
        credentials: 'include',
        headers: {
            'Authorization': `Bearer ${xAuthToken}`
        }
    })
    const creationOptions = await response.json()
    console.log(`Registration result`)
    console.table(creationOptions)

    console.log(`Type is: ${typeof creationOptions}`)
    return creationOptions
}

// Send the public key generate by the browser and user authenticator
const webAuthnFinalize = async (cred: RegistrationPublicKeyCredential) => {
    const xAuthToken = sessionStorage.getItem('hanko') || ''
    const response = await fetch(`${hankoApi}/webauthn/registration/finalize`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${xAuthToken}`
        },
        credentials: "include",
        body: JSON.stringify(cred.toJSON())
    })

    console.log('Finalize registration result')
    console.table(response)
}

export const webAuthnRegistration = async () => {
    const creationOption = await webauthnInit()
    const parsedOptions = parseCreationOptionsFromJSON(creationOption)
    const credentials = await create(parsedOptions)


    console.log(`The credentials Created is`)
    console.table(credentials)

    console.log('The better credentials printout')
    const credJson = await credentials.toJSON()
    console.table(credJson)

    await webAuthnFinalize(credentials)
}