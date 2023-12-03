import styles from '../styles/About.module.css'

export default function About () {
    return (
        <div className={`container ${styles.pageContainer}`}>
            <div className='row'>
                <h1 className={`display-1 col ${styles.pageTitle}`}>{`About`}</h1>

                <p className={`col ${styles.pageParagraph}`}>{'We think COVID forcing online studies has had an impact on students’ mental and physical health. Since this problem is becoming a major concern, our team wanted to dive deeper into learning how students have managed studying and going to school online. We used the data by Dr. Sujatha R. who took information from students to determine the satisfactory level of students learning online. The data includes various attributes such as family size, study time, age etc. that helps determine the overall satisfaction of each student. Our team used the attributes from the dataset to help predict the students’ satisfactions; we used several models to help our prediction. Through our models, our team discovered numerous findings on satisfactory levels of students studying online.'}
                </p>
            </div>
        </div>
    )
}