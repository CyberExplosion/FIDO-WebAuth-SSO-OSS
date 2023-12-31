'use client'

import { PublicKeyCredentialWithAssertionJSON } from "@github/webauthn-json"
import { RegistrationResponseJSON, create, get, parseCreationOptionsFromJSON, parseRequestOptionsFromJSON } from "@github/webauthn-json/browser-ponyfill"

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
const webAuthnFinalize = async (cred: RegistrationResponseJSON) => {    
    const xAuthToken = sessionStorage.getItem('hanko') || ''
    const response = await fetch(`${hankoApi}/webauthn/registration/finalize`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${xAuthToken}`
        },
        credentials: "include",
        body: JSON.stringify(cred)
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

    await webAuthnFinalize(credJson)
}

const webAuthnLoginInit = async (user_id: string) => {
    const data = {
        user_id: user_id
    }
    const logInRes = await fetch(`${hankoApi}/webauthn/login/initialize`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    })

    const logInJson = await logInRes.json()
    console.log(`The return of intializing login`)
    console.table(logInJson)

    return logInJson
}

// Can change the authenticator preference with the transports key value
const webAuthLoginFinalize = async (loginData: PublicKeyCredentialWithAssertionJSON) => {
    const loginFinalizeRes = await fetch(`${hankoApi}/webauthn/login/finalize`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(loginData)
    })
    const loginJson = await loginFinalizeRes.json()

    console.log(`Finalizing the login`)
    console.table(loginJson)
}

export const webAuthnLogin = async (user_id: string) => {
    const requestCredOptions = await webAuthnLoginInit(user_id)
    const parsedOptions = parseRequestOptionsFromJSON(requestCredOptions)
    const assertion = await get(parsedOptions)
    console.log(`The login cred results is:`)
    console.table(assertion)

    await webAuthLoginFinalize(assertion.toJSON())
}

// TODO: Find out why it doesn't do anything
// TODO: shouldn't it log the user out and invalidate the x-auth-token?
export const webAuthnLogOut = async () => {
    const xAuthToken = sessionStorage.getItem('hanko') || ''
    const logoutRes = await fetch(`${hankoApi}/logout`, {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${xAuthToken}`
        },
        credentials: "include"
    })

    const logoutJson = await logoutRes.json()
}