'use client'

import { useEffect } from "react"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

const getHanko = async () => {
  //   const data = {
  //     value: 'abcedfghijklmnopqrstuvwxyz'
  //   }
  // 
  //   const sessionCookieJson = await fetch(`${hankoApi}/token`,
  //     {
  //       method: 'POST',
  //       headers: {
  //         'Content-Type': 'application/json'
  //       },
  //       body: JSON.stringify(data)
  //     })
  //   const sessionCookie = await sessionCookieJson.json()
  // 
  //   console.log(`The session cookie is:`)
  //   console.table(sessionCookie)

  const jsonRes = await fetch(`${hankoApi}/webauthn/registration/initialize`,
    {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer abcedfghijklmnopqrstuvwxyz'
      }
    })

  const result = await jsonRes.json()
  console.log('The initialize registration step')
  console.table(result)

  // Try finalize step
  // const finalizeRes = await fetch(`${hankoApi}/webauth/login/finalize`,
  //   {
  //     method: 'POST',
  //     headers: {
  //       'Content-Type': 'application/json'
  //     }
  //   })
  // const jsonFinalRes = await finalizeRes.json()
  // console.log('The finalize step')
  // console.table(jsonFinalRes)

  // return result
}


export default function Home () {
  useEffect(() => {
    const fetchData = async () => {
      await getHanko()
    }
    fetchData()
  }, [])

  return (
    <>
      <h1>Hello</h1>
    </>
  )
}
