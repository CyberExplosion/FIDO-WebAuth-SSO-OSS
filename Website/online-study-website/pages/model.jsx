import { useRouter } from "next/router"
import Image from "next/image"
import { modelPageContents } from "../src/projectData"
import { useState } from "react"
import { useEffect } from "react"
import styles from '../styles/Models.module.css'

export default function Model () {
    const router = useRouter()
    const {
        query: { pageName }
    } = router

    //USE REACT HOOK STATE here to fix the pageContent doesn't recognize 'imgList' as a key in dictionary (only happen in build)

    const [pageContent, setPageContent] = useState({
        'title': '',
        'details': '',
        'content': ['']
    })


    useEffect(() => {
        setPageContent(previousState => {
            let numOfImgs = modelPageContents[pageName]['imgList'].length
            let imgRows = ['']
            for (let i = 0; i < numOfImgs; i++) {
                imgRows.push(
                    <div className={`text-center ${styles.image}`}>
                        <div className={styles.image}>
                            <Image src={modelPageContents[pageName]['imgList'][i]} width={800} height={600} />
                        </div>
                    </div>
                )
            }

            return {
                ...previousState,
                'title': modelPageContents[pageName]['title'],
                'details': modelPageContents[pageName]['details'],
                'content': imgRows
            }
        })
    }, [pageName])

    return (
        <div className={`container-fluid`}>
            <div className='row'>
                <h1 className={`display-5 col`}>{pageContent['title']}</h1>
                <p className={`col`}>
                    {pageContent['details']}
                </p>
            </div>
            {
                pageContent['content'].map((elem) => {
                    return (elem)
                })
            }
        </div>
    )
}