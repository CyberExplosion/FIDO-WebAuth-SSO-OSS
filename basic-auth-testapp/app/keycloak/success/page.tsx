'use client'

import Keycloak from "keycloak-js"
import { Key, useEffect, useState } from "react"

const init = async (keycloak: Keycloak) => {
    const authenticated = await keycloak.init({})
    // const authenticated = keycloak.authenticated
    if (authenticated) {
        console.log('The user should be authenticated now')
    }
    else {
        console.error('not happend')
    }
}

const requestConfidentialData = async (keycloak: Keycloak) => {
    const body = {
        token: keycloak.token
    }
    const ret = await fetch('https://localhost:3001/api', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: JSON.stringify(body)
    })
    const parsedToken = keycloak.tokenParsed
    console.log(`The parsed token`)
    console.log(JSON.stringify(parsedToken, null, 2))
    console.table(ret)
    
    return ret
}

export default function LoginSuccess () {
    const [keycloak, setKeyCloak] = useState<Keycloak | null>(null)
    const [loggedIn, setLoggedIn] = useState(false)

    useEffect(() => {
        if (typeof window !== 'undefined') {
            const keycloakInstance = new Keycloak({
                url: 'https://localhost:8443',
                realm: 'passwordless',
                clientId: 'basictest'
            })
            setKeyCloak(keycloakInstance)
        }
    }, [])

    useEffect(() => {
        const loadFunc = async () => {
            const auth = await keycloak?.init({})
            if (auth) {
                console.log('User id is')
                console.log(keycloak?.subject)
                setLoggedIn(true)
            }
        }
        loadFunc()
    }, [keycloak])

    if (loggedIn) {
        return (
            <>
                <h1>Success</h1>
                <p>User id: {keycloak?.subject}</p>
                <p>Bearer Token: {keycloak?.token}</p>
                <button onClick={() => requestConfidentialData(keycloak!)}>Test out token</button>
            </>
        )
    }
    else {
        return (
            <h1>Loading....</h1>
        )
    }
}