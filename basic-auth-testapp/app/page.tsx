'use client'

import { useEffect } from "react"

const hankoApi = process.env.NEXT_PUBLIC_HANKO_API_URL
const hankoAdmin = process.env.NEXT_PUBLIC_HANKO_ADMIN_URL

const getHanko = async () => {

  const createUserRes = await fetch(`/api`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
  })

  const createUserJson = await createUserRes.json()

  console.table(createUserJson)

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
