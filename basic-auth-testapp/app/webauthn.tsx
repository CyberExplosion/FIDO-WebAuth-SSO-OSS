'use client'

import { create, parseCreationOptionsFromJSON } from "@github/webauthn-json/browser-ponyfill"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

function printObject (obj: any, indent = 0) {
    const indentation = '  '.repeat(indent);

    for (const key in obj) {
        if (obj.hasOwnProperty(key)) {
            const value = obj[key];
            const valueType = typeof value;

            console.log(`${indentation}${key}: ${valueType}`);

            if (valueType === 'object') {
                // Recursively print nested objects
                printObject(value, indent + 1);
            } else {
                console.log(`${indentation}  ${value}`);
            }
        }
    }
}

// Example usage:
const sampleObject = {
    name: 'John',
    age: 30,
    address: {
        city: 'Example City',
        zip: '12345'
    },
    hobbies: ['reading', 'coding']
};


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

export const webAuthnRegistration = async () => {
    const creationOption = await webauthnInit()
    const parsedOptions = parseCreationOptionsFromJSON(creationOption)
    const credentials = await create(parsedOptions)

    console.log(`The credentials Created is`)
    console.table(credentials)
}