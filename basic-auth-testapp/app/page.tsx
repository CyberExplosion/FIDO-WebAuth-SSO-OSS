'use client'

import { create } from "@github/webauthn-json/browser-ponyfill"
import { useEffect, useState } from "react"
import { webAuthnLogOut, webAuthnLogin, webAuthnRegistration } from "./webauthn"

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

  return userJson
}


export default function Home () {
  const [email, setEmail] = useState('')
  const [currentId, setId] = useState('')

  return (
    <div className="flex flex-col">
      <h1>Hello</h1>
      <label>
        Your email address: 
        <input
          value={email}
          onChange={e => setEmail(e.target.value)}
        />
      </label>
      <button onClick={() => postHanko(email)}>Create new user</button>
      <button onClick={async () => {
        const { id } = await getCurrentHanko()
        setId(id)
      }}>Get current logged in user</button>
      <button onClick={() => webAuthnRegistration()}>Register a webauthn login method</button>
      <button onClick={() => webAuthnLogOut()}>Logout the current user</button>

      <button onClick={() => webAuthnLogin(currentId)}>Login using WebAuthn</button>
      <section about="user-info" className="prose">
        <p>Id name: {currentId}</p>
        <p>Id name: {currentId}</p>
      </section>
    </div>
  )
}
