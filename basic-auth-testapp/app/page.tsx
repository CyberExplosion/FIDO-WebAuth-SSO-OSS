'use client'

import { create } from "@github/webauthn-json/browser-ponyfill"
import { useEffect } from "react"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL
const hankoAdmin = process.env.NEXT_PUBLIC_HANKO_ADMIN_URL

const postHanko = async () => {
  const createUserRes = await fetch(`${hankoApi}/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    mode: "cors",
    credentials: 'include',
    body: JSON.stringify({ email: 'basbsdf@gmail.com'})
  })

  const createUserJson = await createUserRes.json()

  console.table(createUserJson)
}

const getCurrentHanko = async () => {
  // Use the current hanko cookie to fetch the account
  const userRes = await fetch(`${hankoApi}/me`, {
    method: 'GET',
    credentials: "include",
  })
  const userJson = await userRes.json()
  console.log('The user id is')
  console.table(userJson)
}


// Need to have hanko cookie (signed in)
const webAuthnRegistration = async () => {
  const response = await fetch(`${hankoApi}/webauthn/registration/initialize`, {
    method: 'POST',
    credentials: 'include'
  })
  const responseJson = await response.json()

  console.log(`Registration result`)
  console.table(responseJson)
}

const webAuthnLogin = async (id: string) => {
  const body = { user_id: 'd223da8f-bc49-4db1-bad4-9e59b511900a' }
  // const encodedBody = create(body)

  const response = await fetch('/api/webauthn', {
    method: 'POST',
    body: JSON.stringify(body)
  })
  const responseJson = await response.json()
  console.log(`Result from initialize webauthn`)
  console.table(responseJson)
}

export default function Home () {
  const testingUserId = '0d80b714-a0e1-4916-9c31-8be6fd8bc2dc'


  return (
    <div className="flex flex-col">
      <h1>Hello</h1>
      <button onClick={() => postHanko()}>Create new user</button>
      <button onClick={() => getCurrentHanko()}>Get current logged in user (from cookie)</button>
      <button onClick={() => webAuthnRegistration()}>Register a webauthn login method</button>
      <button onClick={() => webAuthnLogin(testingUserId)}>Initialize webAuthnLogin</button>
    </div>
  )
}
