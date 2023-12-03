import GraphPresent from "./GraphPresent";
import Image from 'next/image'
import { CarouselItems } from "../src/carousel_items";

export default function GraphCarousel () {
    return (
        <div id="carousel" className={`carousel slide carousel-dark`} data-bs-ride="carousel">
            <div className="carousel-indicators">
                {
                    CarouselItems.map((_, index) => {
                        if (index == 0) {
                            return (
                                <button type="button" data-bs-target="#carousel" data-bs-slide-to={index} className="active" aria-current="true" aria-label={`Slide ${index + 1}`}></button>
                            )
                        }
                        else {
                            return (
                                <button type="button" data-bs-target="#carousel" data-bs-slide-to={index} aria-label={`Slide ${index + 1}`}></button>
                            )
                        }
                    })
                }
            </div>
            <div className="carousel-inner">
                {
                    CarouselItems.map((elem, index) => {
                        if (index == 0) {
                            return (
                                <div className="carousel-item active" data-bs-toggle="modal" data-bs-target="#firstModal">
                                    <GraphPresent
                                        graphName={elem.graphName}
                                        desc={elem.desc}
                                        imgURL={elem.imgURL} />
                                    <div className="modal fade" id="firstModal" tabIndex="-1" role="dialog" aria-labelledby="firstModalLabel" aria-hidden="true">
                                        <div className="modal-dialog modal-fullscreen">
                                            <div className="modal-content">
                                                <div className="modal-body">
                                                    <Image src={elem.imgURL} layout='fill' />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            )
                        } else {
                            return (
                                <div className="carousel-item" data-bs-toggle="modal" data-bs-target={`#Modal-${index}`}>
                                    <GraphPresent
                                        graphName={elem.graphName}
                                        desc={elem.desc}
                                        imgURL={elem.imgURL} />
                                    <div className="modal fade" id={`Modal-${index}`} tabIndex="-1" aria-labelledby={`${index}ModalLabel`} aria-hidden="true">
                                        <div className="modal-dialog modal-fullscreen">
                                            <div className="modal-content">
                                                <div className="modal-body">
                                                    <Image src={elem.imgURL} layout='fill' />
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            )
                        }
                    })
                }
            </div>
            <button className={`carousel-control-prev`} type="button" data-bs-target="#carousel" data-bs-slide="prev">
                <span className="carousel-control-prev-icon" aria-hidden="true"></span>
                <span className="visually-hidden">Previous</span>
            </button>
            <button className="carousel-control-next" type="button" data-bs-target="#carousel" data-bs-slide="next">
                <span className="carousel-control-next-icon" aria-hidden="true"></span>
                <span className="visually-hidden">Next</span>
            </button>
        </div >
    )
}