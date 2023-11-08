'use client'

import { useEffect } from "react"
import { Hanko, UnauthorizedError } from "@teamhanko/hanko-frontend-sdk"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL

const getHanko = async () => {
  const hanko = new Hanko(hankoApi as string)

  try {
    const user = await hanko.user.getCurrent()
    console.log('Here is the user')
    console.table(user)
  }
  catch (e) {
    if (e instanceof UnauthorizedError) {
      console.log('some error')
    }
  }
  //   const jsonRes = await fetch(`${hankoApi}/webauthn/login/initialize`,
  //     {
  //       method: 'POST',
  //       headers: {
  //         'Content-Type': 'application/json'
  //       },
  //     })
  // 
  //   const result = await jsonRes.json()
  //   console.log('The initialize login step')
  //   console.table(result)

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


  return (
    <>
      <h1>Hello</h1>
      <button onClick={() => getHanko()}>Click</button>
    </>
  )
}
