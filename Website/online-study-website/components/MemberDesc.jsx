import styles from './styles/MemberDesc.module.css'
import Image from 'next/image'

export default function MemberDesc ({ name, desc, profileURL }) {
    return (
        <div className={`card border-0 ${styles.container}`}>
            <div className={`card-img-top`}>
                <div className={styles.imgWrapper}>
                    <Image src={profileURL} width='484px' height='460px' />
                </div>
            </div>
            {/* <img className={`card-img-top ${styles.image}`} src={profileURL} /> */}
            <div className={`card-body ${styles.cardBody}`}>
                <h5 className={`text-center ${styles.name}`}>{name}</h5>
                <p className={`card-text ${styles.desc}`}>{desc}</p>
            </div>
        </div>
    )
}