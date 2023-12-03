import Image from "next/image";
import { useEffect, useState } from "react";
import { Dropdown, DropdownButton } from "react-bootstrap";
import { modelPageContents } from "../src/projectData";
import styles from '../styles/Compare.module.css'

export default function Compare () {
    const [firstData, setFirstData] = useState({
        title: "Pick model to compare",
        details: "",
        imgList: [""],
        confusion: "",
        report: "",
        graphs: [""],
        modelPicPath: ''
    });
    const [secondData, setSecondData] = useState({
        title: "Pick model to compare",
        details: "",
        imgList: [""],
        confusion: "",
        report: "",
        graphs: [""],
    });
    const update = (graphTitle, setFunction) => {
        setFunction(previousState => {
            return {
                ...previousState,
                title: modelPageContents[graphTitle]['title'],
                details: modelPageContents[graphTitle]['details'],
                imgList: modelPageContents[graphTitle]['imgList'],
                confusion: modelPageContents[graphTitle]['confusion'],
                report: modelPageContents[graphTitle]['report'],
                graphs: modelPageContents[graphTitle]['graphs'],
                modelPicPath: modelPageContents[graphTitle]['modelPicPath']
            }
        });
    }

    const [firstLoad, setFirstLoad] = useState(true)
    const [secondLoad, setSecondLoad] = useState(true)

    const [compareElem, setCompareElem] = useState({
        'imgElem': [],
        'confusion': [],
        'report': [],
        'graphs': []
    })
    //IN order to use useEffect, needs to be use on a state value
    useEffect(() => {   //Make dictionary of elements so that it's easier to organize things later
        if (!firstLoad && secondLoad) {
            setCompareElem(() => {
                return {
                    'imgElem': (
                        <div className="row">
                            <div className="col">
                                <Image src={firstData.modelPicPath} width={300} height={300} />
                            </div>
                        </div>
                    ),
                    "confusion": (
                        <div className="row border-top">
                            <h2 className="display-5">Confusion Matrix</h2>
                            <div className="col text-center">
                                <Image src={firstData.confusion} width={400} height={400} />
                            </div>
                        </div>
                    ),
                    "report": (
                        <div className="row border-top">
                            <h2 className="display-5">Classification Report</h2>
                            <div className="col text-center">
                                <div className={styles.imgWrapper}>
                                    <Image src={firstData.report} width={1100} height={400} />
                                </div>
                            </div>
                        </div>
                    ),
                    "graphs": (
                        <div className="row border-top">
                            <h2 className="display-5">Graphs</h2>
                            <div className="col text-center">
                                {
                                    firstData.graphs.map((elem, index) => {
                                        return (
                                            <div className="img-fluid" key={index}>
                                                <Image src={elem} width={300} height={300} />
                                            </div>
                                        )
                                    })
                                }
                            </div>
                        </div>
                    )
                }
            })
        }
        if (firstLoad && !secondLoad) {
            setCompareElem(() => {
                return {
                    'imgElem': (
                        <div className="row">
                            <div className="col"></div>
                            <div className="col">
                                <Image src={secondData.imgList[0]} width={500} height={500} />
                            </div>
                        </div>
                    ),
                    "confusion": (
                        <div className="row border-top">
                            <h2 className="display-5">Confusion Matrix</h2>
                            <div className="col text-center">
                                <Image src={secondData.confusion} width={400} height={400} />
                            </div>
                        </div>
                    ),
                    "report": (
                        <div className="row border-top">
                            <h2 className="display-5">Classification Report</h2>
                            <div className="col text-center">
                                <div className={styles.imgWrapper}>
                                    <Image src={secondData.report} width={1100} height={400} />
                                </div>
                            </div>
                        </div>
                    ),
                    "graphs": (
                        <div className="row border-top">
                            <h2 className="display-5">Graphs</h2>
                            <div className="col text-center">
                                {
                                    secondData.graphs.map((elem, index) => {
                                        return (
                                            <div className="img-fluid" key={index}>
                                                <Image src={elem} width={300} height={300} />
                                            </div>
                                        )
                                    })
                                }
                            </div>
                        </div>
                    )
                }
            })
        }
        if (!firstLoad && !secondLoad) {
            setCompareElem(() => {
                return {
                    'imgElem': (
                        <div className="row">
                            <div className="col text-center">
                                <Image src={firstData.imgList[0]} width={500} height={500} />
                            </div>
                            <div className="col text-center">
                                <Image src={secondData.imgList[0]} width={500} height={500} />
                            </div>
                        </div>
                    ),
                    "confusion": (
                        <div className="row border-top">
                            <h2 className="display-5">Confusion Matrix</h2>
                            <div className="col text-center">
                                <Image src={firstData.confusion} width={1100} height={400} />
                            </div>
                            <div className="col text-center">
                                <Image src={secondData.confusion} width={1100} height={400} />
                            </div>
                        </div>
                    ),
                    "report": (
                        <div className="row border-top">
                            <h2 className="display-5">Classification Report</h2>
                            <div className="col text-center">
                                <div className={styles.imgWrapper}>
                                    <Image src={firstData.report} width={1100} height={400} />
                                </div>
                            </div>
                            <div className="col text-center">
                                <div className={styles.imgWrapper}>
                                    <Image src={secondData.report} width={1100} height={400} />
                                </div>
                            </div>
                        </div>
                    ),
                    "graphs": (
                        <div className="row border-top">
                            <h2 className="display-5">Graphs</h2>
                            <div className="col text-center">
                                {
                                    firstData.graphs.map((elem, index) => {
                                        return (
                                            <div className="img-fluid" key={index}>
                                                <Image src={elem} width={300} height={300} />
                                            </div>
                                        )
                                    })
                                }
                            </div>
                            <div className="col text-center">
                                {
                                    secondData.graphs.map((elem, index) => {
                                        return (
                                            <div className="img-fluid" key={index}>
                                                <Image src={elem} width={300} height={300} />
                                            </div>
                                        )
                                    })
                                }
                            </div>
                        </div>
                    )
                }
            })
        }
    }, [firstData, secondData])


    return (
        <div className="container" key={0}>
            <div className="row">
                <div className="col text-center">
                    <h1 className="display-3">{`${firstData.title}`}</h1>
                    <Dropdown>
                        <DropdownButton
                            id={`dropdown-variants-Secondary`}
                            variant={`secondary`}
                            title={`${firstData.title}`}
                            key={0}
                        >
                            {
                                Object.entries(modelPageContents).map(([key, value]) => {
                                    if (value.title != 'Pre-Processing') {
                                        return (
                                            <Dropdown.Item
                                                as='button'
                                                eventKey={key}
                                                onClick={() => { update(value.title, setFirstData), setFirstLoad(false) }}
                                                key={key}
                                            >
                                                {value.title}
                                            </Dropdown.Item>
                                        )
                                    }
                                })
                            }
                        </DropdownButton>
                    </Dropdown>
                </div>
                <div className="col text-center">
                    <h1 className="display-3">{`${secondData.title}`}</h1>
                    <Dropdown>
                        <DropdownButton
                            id={`dropdown-variants-Secondary`}
                            variant={`secondary`}
                            title={`${secondData.title}`}
                            key={1}
                        >
                            {
                                Object.entries(modelPageContents).map(([key, value]) => {
                                    if (value.title != 'Pre-Processing') {
                                        return (
                                            <Dropdown.Item
                                                as='button'
                                                eventKey={key}
                                                onClick={() => { update(value.title, setSecondData), setSecondLoad(false) }}
                                                key={key}
                                            >
                                                {value.title}
                                            </Dropdown.Item>
                                        )
                                    }
                                })
                            }
                        </DropdownButton>
                    </Dropdown>
                </div>
            </div>
            {
                compareElem['confusion']
            }
            {
                compareElem['report']
            }
            {
                compareElem['graphs']
            }
        </div>
    )
}