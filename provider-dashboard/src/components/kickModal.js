import React from 'react'

import { Button, Modal } from 'react-bootstrap'

const { Body } = Modal


const ConfirmDeleteModal = (props) => {

    const { modalState, fixed, triggerModal, nameOfTarget, deleteTarget, message, buttonText, deleting} = props

    return (

          <Modal show={modalState} onHide={triggerModal}
          backdrop={fixed ? 'static':null} keyboard={fixed ? false : true} 
          dialogClassName="confirm-delete-modal">
            <Body style={{height: 'fit-content'}}>
              <div style={{textAlign: 'center', verticalAlign: 'middle',paddingLeft: 20, paddingRight: 20, paddingTop: 20, paddingBottom: 20,}}>
                <h2>Are you sure?</h2>
                {message ? message :
                   <div>
                    {nameOfTarget && 
                      <p>Kick "{nameOfTarget}"?</p>
                    }
                  </div>
                }
                <div style={{ marginTop: 20 }}>
                  <Button 
                  bsStyle="default" 
                  disabled={buttonText ? deleting : null}
                  onClick={()=>triggerModal()}>
                    Back
                  </Button>
                  <Button
                    style={{ marginLeft: 10 }}
                    bsStyle="danger"
                    disabled={buttonText ? deleting : null}
                    onClick={()=>deleteTarget()}>
                    {buttonText ? <span>Cancel</span> : <span>Kick</span>}
                  </Button>
                </div>
              </div>
            </Body>
          </Modal>
          )
  }