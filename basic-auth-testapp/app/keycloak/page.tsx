'use client'

import Keycloak from "keycloak-js";
import { useEffect, useState } from "react";

const login = async (keycloak: Keycloak) => {
    const authenticated = await keycloak.init({})
    if (authenticated) {
        console.error('The user is authenticated, user should not still be here')
    }
    else {
        const res = await keycloak.login({ redirectUri: 'https://localhost:3000/keycloak/success' })
    }
}

// Check if keycloak isalready init before doing init again
export default function KeyCloakHome () {
    const [keycloak, setKeyCloak] = useState<Keycloak | null>(null)

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


    return (
        <>
            <h1>Hello</h1>
            <button onClick={() => login(keycloak!)}>Log in</button>
        </>
    )

}