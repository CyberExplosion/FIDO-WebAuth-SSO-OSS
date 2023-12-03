import Link from 'next/link'
import styles from './styles/Header.module.css'
import { useRouter } from 'next/router'
import { modelPageContents } from '../src/projectData';
import { NavDropdown, NavLink } from 'react-bootstrap';

export default function Header () {
    const cur_path = useRouter().pathname;

    return <>
        <nav className="navbar sticky-top navbar-expand-lg navbar-light bg-light border-top mb-5">
            <div className='container-fluid justify-content-between'>
                <Link href='/' className={`navbar-brand mb-0 h1 ${styles.title}`}>
                    Online Study Prediction
                </Link>
                <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                    <span className="navbar-toggler-icon"></span>
                </button>

                <div className="collapse navbar-collapse" id="navbarNav">
                    <ul className="navbar-nav ms-auto mb-2 mb-lg-0">
                        <li className="nav-item">
                            <Link
                                href='/'
                                className={cur_path == '/' ? 'nav-link active text-decoration-underline' : 'nav-link'}
                                aria-current="page">
                                Home
                            </Link>
                        </li>
                        <li className="nav-item">
                            <Link
                                href='/about'
                                className={cur_path == '/about' ? 'nav-link active text-decoration-underline' : 'nav-link'}>
                                About
                            </Link>
                        </li>
                        <NavDropdown title="Models" id="basic-nav-dropdown">
                            {
                                Object.entries(modelPageContents).map(([key, value]) => {
                                    return (
                                        <NavDropdown.Item key={key}>
                                            <Link href={{
                                                pathname: '/model',
                                                query: { pageName: value['title'] }
                                            }}>
                                                {value['title']}
                                            </Link>
                                        </NavDropdown.Item>
                                    );
                                })
                            }
                        </NavDropdown>
                        <li className='nav-item'>
                            <Link
                                href='/compare'
                                className={cur_path == '/compare' ? 'nav-link active text-decoration-underline' : 'nav-link'}>
                            Compare
                            </Link>
                        </li>
                        <li className='nav-item'>
                            <Link
                                href='/predict'
                                className={cur_path == '/predict' ? 'nav-link active text-decoration-underline' : 'nav-link'}>
                            Predict
                            </Link>
                        </li>
                    </ul>
                </div>
            </div>
        </nav>
    </>;
}