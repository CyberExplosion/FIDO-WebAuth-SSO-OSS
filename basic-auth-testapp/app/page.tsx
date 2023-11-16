'use client'

import { create } from "@github/webauthn-json/browser-ponyfill"
import { useEffect, useState } from "react"
import { webAuthnRegistration } from "./webauthn"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL
const hankoAdmin = process.env.NEXT_PUBLIC_HANKO_ADMIN_URL

// Use x-auth-token instead of cookie to work with chrome not allowing cross-domain cookies
const postHanko = async (email: string) => {
  const createUserRes = await fetch(`${hankoApi}/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    mode: "cors",
    credentials: 'include',
    body: JSON.stringify({ email: email })
  })

  const xAuthToken = createUserRes.headers.get('X-Auth-Token') || ''
  sessionStorage.setItem("hanko", xAuthToken)
  console.log(`The auth token is: ${xAuthToken}`)
  const createUserJson = await createUserRes.json()

  console.table(createUserJson)
}

const getCurrentHanko = async () => {
  // Use the current hanko cookie to fetch the account
  const xAuthToken = sessionStorage.getItem('hanko') || ''
  const userRes = await fetch(`${hankoApi}/me`, {
    method: 'GET',
    credentials: "include",
    headers: {
      'Authorization': `Bearer ${xAuthToken}`
    }
  })
  const userJson = await userRes.json()
  console.log('The user id is')
  console.table(userJson)
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
  const [email, setEmail] = useState('')

  return (
    <div className="flex flex-col">
      <h1>Hello</h1>
      <label>
        Your email address
        <input
          value={email}
          onChange={e => setEmail(e.target.value)}
        />
      </label>
      <button onClick={() => postHanko(email)}>Create new user</button>
      <button onClick={() => getCurrentHanko()}>Get current logged in user (from cookie)</button>
      <button onClick={() => webAuthnRegistration()}>Register a webauthn login method</button>
    </div>
  )
}
