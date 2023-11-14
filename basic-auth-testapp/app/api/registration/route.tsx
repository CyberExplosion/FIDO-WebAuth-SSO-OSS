const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

export async function POST () {
    const registrationRes = await fetch(`${hankoApi}/webauthn/registration/initialize`)
    const registrationJson = await registrationRes.json()

    console.log(`Result return from registration`)
    console.table(registrationJson)
}