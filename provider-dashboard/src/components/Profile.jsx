import React, { Component } from 'react';
import {
  isSignInPending,
  loadUserData,
  Person,
} from 'blockstack';
import ExchangeConsole from './exchangeConsole'
import moment from 'moment'
import KickModal from './kickModal'
import ReconnectingWebSocket from 'reconnecting-websocket'


const avatarFallbackImage = 'https://s3.amazonaws.com/onename/avatar-placeholder.png';

export default class Profile extends Component {
  constructor(props) {
  	super(props);

  	this.state = {
  	  person: {
  	  	name() {
          return 'Anonymous';
        },
  	  	avatarUrl() {
  	  	  return avatarFallbackImage;
  	  	},
  	  },
      devices: [],
      history: [],
      showWallet:false,
      modalState: false,
      nameOfTarget: null,
      deleting: null,

  	};

    this.walletClick = this.walletClick.bind(this)
    this.triggerModal = this.triggerModal.bind(this)
    this.warnBeforeDelete = this.warnBeforeDelete.bind(this)
    this.deleteTarget = this.deleteTarget.bind(this)
    this.webhookHandler = this.webhookHandler.bind(this)


    this.ws = new ReconnectingWebSocket('ws://localhost:80')
    this.ws.onmessage = (e) => {
     console.log(e)
     let d = null
     try{d=JSON.parse(e.data)}catch(e){}
     if(d) {
        if(d.type==='CONFIRMED'){
          this.webhookHandler()
        }
        if(d.type==='MESSAGE'){
          console.log("MESSAGE, ",d.text)
          const devices = this.state.devices
          devices[0].messages.push(d.text)
          this.setState({devices})
        }
     }
    }
    this.ws.onopen = function(e) {
     console.log("WEBSOCKET CONNECTED!!!",e)
    }
    this.ws.onerror = function(e) {
      console.log(e)
    }
    this.ws.onclose = function(e) {
      console.log('closssee!')
    }

    console.log(this.ws)


  }

  componentDidMount(){
    //this.webhookHandler()
    
  }

  walletClick() {
    let { showWallet } = this.state
    showWallet = !showWallet

    this.setState({showWallet})
  }

  triggerModal() {
    let modal = this.state.modal
    modal = !modal
    this.setState({ modal })
  }

  warnBeforeDelete(a, e) {
    this.setState({ selectedForDelete: e })
    this.triggerModal()
  }

  deleteTarget() {
  const { selectedForDelete } = this.state

      this.setState({
        isDeleting: selectedForDelete.id,
        selectedForDelete: null
      })
      this.triggerModal()
    }


    webhookHandler(){
      const device = [
        {
          hash:'mydevice',
          connectedAt: moment(Date.now()).add(0, 'year').format('LL'),
          time:60000 * .5,
          usedtime: 0,
          data:'2GB',
          payment:1000,
          messages:[]
        }
    ]

    const history = this.state.history

    history.push(device[0])

      this.setState({devices: device, history})

      this.deviceTimer = setInterval(()=>{
        let devices = this.state.devices
        devices[0].usedtime+=100
        //if time is up remove device
        if ((devices[0].time - devices[0].usedtime) < 0){
          this.setState({devices:[]})
          clearInterval(this.deviceTimer)
          this.ws.send(`{"type":"TIMEOUT"}`)
        }
        else{
        this.setState({devices})
        }
      }, 100)
    }

  render() {
    const { handleSignOut } = this.props;
    const { person, showWallet, modalState, nameOfTarget, deleting, devices, history } = this.state;

    return (
      !isSignInPending() ?
      <div style={{height:'100%'}} className="" id="">

          <div style={styles.sidebar}>
          <div style={styles.userInfo}>
              <img src={ person.avatarUrl() ? person.avatarUrl() : avatarFallbackImage } className="img-rounded avatar" id="avatar-image" />
          </div>
          {/*}
          <div className="btn btn-primary btn-lg" style={styles.viewWallet}
          onClick={()=>{this.walletClick()}}>
          Wallet
          </div>
        */}

        <div className="btn btn-primary btn-lg" style={styles.viewWallet}
          onClick={()=>{this.walletClick()}}>
          Wallet
          </div>
          <div style={styles.logout}>
              <button
                className="btn btn-primary btn-lg"
                id="signout-button"
                onClick={ handleSignOut.bind(this) }
              >
                Logout
              </button>
          </div>
            
        </div>

        
       {/* <h1><span id="">{ person.name() ? person.name() : 'Trifi Admin' }</span></h1> */}
       <div style={{marginBottom:60}}>
        <h3>{devices && devices.length > 0 ? devices.length : 'No'} users connected.</h3>
        </div>

        <ExchangeConsole
        devices={devices}
        history={history}
        showWallet={showWallet}
        triggerModal={this.triggerModal} 
        />

        {/*}
        <KickModal 
        modalState={modalState} 
        fixed={true}
        triggerModal={this.triggerModal} 
        nameOfTarget={nameOfTarget}
        deleteTarget={this.deleteTarget} 
        deleting={deleting}
        />
      */}

      </div> : null
    );
  }

  componentWillMount() {
    this.setState({
      person: new Person(loadUserData().profile),
    });
  }
}

const styles = {
  sidebar: {
    float:'right',
    width:140,
    background:'#000000b1',
    height:'100%',
    zIndex:10
  },
  logout: {
    margin:5,
  },
  userInfo: {
    margin:5,
    marginTop:20
  },
  viewWallet: {
    margin:5,
  }
}
