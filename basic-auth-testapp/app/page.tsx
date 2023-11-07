'use client'

import { useEffect } from "react"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

const getHanko = async () => {
  const jsonRes = await fetch(`${hankoApi}/webauthn/login/initialize`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    })
  
  const result = await jsonRes.json()

  return result
}

const init = () => getHanko()

export default function Home () {
  useEffect(() => {
    const res = init()
    console.log('the result is')
    console.table(res)
  }, [])

  return (
    <>
      <h1>Hello</h1>
    </>
  )
}
