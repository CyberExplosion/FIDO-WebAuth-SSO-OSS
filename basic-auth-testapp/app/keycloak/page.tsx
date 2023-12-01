'use client'

import Keycloak from "keycloak-js";
import { useEffect } from "react";


const defaultFunc = async (keycloak: Keycloak) => {
    try {
        const authenticated = await keycloak.init({
            onLoad: 'login-required'
        })
        console.log(`User is ${authenticated ? 'authenticated' : 'not authenticated'}`);
        console.log('user profile')
        console.table(await keycloak.loadUserProfile())
    } catch (error) {
        console.error('Failed to initialize adapter:', error);
    }
}

const login = async (keycloak: Keycloak) => {
    const res = await keycloak.login({ redirectUri: 'https://localhost:3000/keycloak/success' })
    return res
}

export default function KeyCloakHome () {
    const keycloak = new Keycloak({
        url: 'https://localhost:8443',
        realm: 'passwordless',
        clientId: 'basictest'
    })
    keycloak.init({})
    useEffect(() => {
        const result = login(keycloak)
        console.log('the result is:')
        console.table(result)
    }, [])

    return (
        <h1>Hello</h1>
    )
}