import styles from './styles/ProjectCard.module.css'
import Link from 'next/link'
import Image from 'next/image'

export default function ProjectCard ({ imgURL, cardTitle, pageLink }) {
    return (
        <div className={`card border-0 mb-5 ${styles.container}`}>
            <div className='card-img-top text-center'>
                <div className={styles.imgWrapper}>
                    <Image src={imgURL} width={1192} height={594} />
                </div>
            </div>
            <div className={`card-body container-fluid mt-5 ${styles.cardBody}`}>
                <div className='row'>
                    <div className='col'>
                        <h5 className={`card-title ${styles.cardTitle}`} style={{ height: '50%' }}><strong>{cardTitle}</strong></h5>
                    </div>
                    <div className='col text-end' style={{ height: '100%' }}>
                        <Link href={pageLink} className='btn btn-dark p-2'>
                            <strong>See Model</strong>
                        </Link>
                    </div>
                </div>
            </div>
        </div>
    );
}