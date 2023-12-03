import { useState } from "react"
import { Dropdown, DropdownButton } from "react-bootstrap";


export default function InputItem ({ type, question, choices, setStateFunc }) {
    const [option, setOption] = useState('Pick your choices')

    return (
        <div className='text-center'>
            <h5>{question}</h5>
            {
                type == 'numeric' ? (
                    <div className="form">
                        <form>
                            <input type='text' onChange={
                                (event) => setStateFunc(previous => {
                                    console.log(event.target.value)
                                    return {
                                        ...previous,
                                        [question]: event.target.value
                                    }
                                })} />
                        </form>
                    </div>
                ) : (
                    <div className="dropDown">
                        <DropdownButton
                            variant={'info'}
                            title={option}
                            key={0}
                        >
                            {
                                choices.map((value, index) => {
                                    return (
                                        <Dropdown.Item
                                            as={'button'}
                                            eventKey={index}
                                            key={index}
                                            onClick={() => {
                                                setOption(value)
                                                setStateFunc(previous => {
                                                    return {
                                                        ...previous,
                                                        [question]: value
                                                    }
                                                })
                                            }}
                                        >
                                            {value}
                                        </Dropdown.Item>
                                    )

                                })
                            }
                        </DropdownButton>
                    </div>
                )
            }

        </div>
    )
}