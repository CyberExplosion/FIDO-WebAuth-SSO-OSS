'use client'

const INTROSPECT = 'https://127.0.0.1:8443/realms/passwordless/protocol/openid-connect/token/introspect'
const APISECRET = '671YynETbhhNvXPR3t0SnqdktgPlR7bo'
const CLIENTID = 'backend'

const click = async () => {
  const basicAuth = btoa(`${CLIENTID}:${APISECRET}`)
  const ret = await fetch(INTROSPECT, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authorization": `Basic ${basicAuth}`
    },
    body: JSON.stringify({ token: 'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJyc3Z4VlFpdjNESXVFN1FGSTMtamlidVlKSTZJTElreDJfeng5SWxoS0tZIn0.eyJleHAiOjE3MDE0MzI0MjMsImlhdCI6MTcwMTQxNDQyMywiYXV0aF90aW1lIjoxNzAxNDEzODAxLCJqdGkiOiJiMmE4MzMzNy1jM2VmLTRjZDAtYTBlNy1mMzc1OTc4ZmI3YzUiLCJpc3MiOiJodHRwczovL2xvY2FsaG9zdDo4NDQzL3JlYWxtcy9wYXNzd29yZGxlc3MiLCJhdWQiOiJhY2NvdW50Iiwic3ViIjoiNzRlZjhmNDMtM2Q5ZC00Y2U5LWFiNDQtYmI0ZTNjNmVhMDI0IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiYmFzaWN0ZXN0Iiwibm9uY2UiOiJlZWU0MDExMS1mZWY4LTQ4ZTctOGVmNC1kOGVjNzFiNWM2OWEiLCJzZXNzaW9uX3N0YXRlIjoiYTUxNjU4YzItZDNiZS00M2RmLTg0ZWYtZTA5MzZiMDQ3NWIwIiwiYWNyIjoiMCIsImFsbG93ZWQtb3JpZ2lucyI6WyIqIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJkZWZhdWx0LXJvbGVzLXBhc3N3b3JkbGVzcyIsIm9mZmxpbmVfYWNjZXNzIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6Im9wZW5pZCBwcm9maWxlIGVtYWlsIiwic2lkIjoiYTUxNjU4YzItZDNiZS00M2RmLTg0ZWYtZTA5MzZiMDQ3NWIwIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5hbWUiOiJ0ZXN0IHRlc3QiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJ0ZXN0IiwiZ2l2ZW5fbmFtZSI6InRlc3QiLCJmYW1pbHlfbmFtZSI6InRlc3QifQ.ZCPw6EwkHXqgiZsqqnp_52prTz_YplQ9-ZROsB_2GSORZQ-aHmPDGn0aCutKxI8GBK2fTPMqw6gYir7El0D7DUGk2zWDQV-mLHw08Sdb_Aqm5q82JTu9mFcsKEVhpldoDWvEC15DsG04Q0Rx2TYEg_dmhlPVBAOvLg6-5WdG2D6W8R7dm_T1OyZZD1juJY4IeobOT-qvlLhQlCkpeMV42RW4dAX-ucdlmOGJQ1kp4H4iiDUzF8YVjsTyqgE8VJSgtYkOqQUjFg2YYNKGaQXtivYp-K06eUVhXFG5H278qijj_yqOaWXzznF33yo329uY_fBHVWKRslirinFQ7vbwrw' })
  })
  const retJson = await ret.json()
  console.log(`Result of fetch: ${JSON.stringify(retJson)}`)
}


export default function Home () {

  return (
    <>
      <h1>Home page unused</h1>
      {/* <button onClick={() => click()}>Clik me</button> */}
    </>
  )
}