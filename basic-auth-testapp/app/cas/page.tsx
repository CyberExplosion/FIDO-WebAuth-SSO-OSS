'use client'

const CASLogin = 'https://localhost:8443/cas/login'

export default function CAS () {
    const doLogin = () => {
        const serviceURL = `${CASLogin}?service=${encodeURIComponent('https://localhost:3000/cas')}`
        window.location.href = serviceURL
    }
    
    return (
        <>
            <h1>Going to CAS login...</h1>
            <button onClick={() => doLogin()} className="btn">Login to CAS</button>
        </>
    )
}