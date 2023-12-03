import Link from 'next/link'
import styles from './styles/Footer.module.css'

export default function Footer () {
    return (
        <footer className={`container-fluid mx-3 border-top ${styles.container}`}>
            <h2 className={`my-4 ${styles.teamName}`}>Online Study Prediction</h2>
            <div className={`row ${styles.contactContainer}`}>
                <ul className={`col-3 ${styles.leftCol}`}>
                    <p className={styles.contactDetails}>University of California, Davis One Shields Avenue</p>
                    <p className={styles.contactDetails}>Davis, CA 95616</p>
                </ul>
                <ul className={`col ${styles.rightCol}`}>
                    <p className={styles.contactDetails}>530-752-1011</p>
                    <Link href='mailto:cyberhyperwave@gmail.com' className={styles.contactDetails}>
                        cyberhyperwave@gmail.com
                    </Link>
                </ul>
            </div>
        </footer>
    );
}