import Image from 'next/image'

export default function GraphPresent ({ graphName, desc, imgURL }) {
    return (
        <>
            <div className="container">
                <div className="row">
                    <div className="col-5">
                        <h1 className="display-5">{graphName}</h1>
                    </div>
                    <div className='col'>
                        <p>{desc}</p>
                    </div>
                </div>
                <div className="row justify-content-center mt-5">
                    <div className="col-auto">
                        <Image src={imgURL} width='1230px' height='630px' />
                    </div>
                </div>
            </div>
        </>
    )
}