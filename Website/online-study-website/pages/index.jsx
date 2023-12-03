import ProjectCard from '../components/ProjectCard'
import styles from '../styles/Home.module.css'
import { models } from '../src/projectData'

export default function Home () {
  return (
    <div className={`container ${styles.container}`}>
      <h1 className={`display-5 ${styles.pageTitle}`}>{`Our projects`}</h1>
      <div className={`mt-5 ${styles.projectSection}`}>
        {
          models.map((elem, index) => {
            return (
              <div className='row mt-5' key={index}>
                <ProjectCard
                  cardTitle={elem.modelName}
                  cardText={elem.modelDetails}
                  imgURL={elem.modelPicPath}
                  pageLink={elem.modelPageURL} />
              </div>
            )
          })
        }
      </div>
    </div>
  )
}
