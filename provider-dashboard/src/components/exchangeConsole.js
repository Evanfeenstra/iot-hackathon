import React, { Component } from 'react';
import { ResponsivePie } from 'nivo'
import {IotaProvider, Wallet, Curl} from "react-iota"
import { Modal, Button } from 'antd'
import moment from 'moment'
import IotaLogo from './iotalogo'

export default class ExchangeConsole extends Component {
constructor(props) {
    super(props);
    
    this.state = {
      visible: false,
      // history: null
    }

    this.toggleModal = this.toggleModal.bind(this)
  }

  // componentDidMount(){
  //   const { devices } = this.props 
  //   if (devices.length > 0){
  //     const history = []
  //     devices.map((o)=>{
  //       history.push(o)
  //     })

  //     this.setState({history})
  //   }
  // }

  toggleModal(){
    let { visible } = this.state
    visible = !visible
    this.setState({visible})
  }

  render() {

    // const { history } = this.state
    const { triggerModal, history, devices } = this.props

    return (
      <div style={{textAlign:'left',overflow:'hidden'}}>
      <div style={styles.devicesEnvelope}>
      <div style={{textAlign:'center', color: '#ffffffb1'}}>
      <h4>Live Connections</h4>
       
      </div>
      {devices.length < 0 && 
        <div className="">
        No Connections.
        </div>
      }

      { devices.map((o,i)=>{

        const piedata = [
          {
            "id": "used time",
            "label": "used time",
            "value": o.usedtime,
            "color": "hsl(229, 70%, 50%)"
          },
          {
            "id": "remaining time",
            "label": "remaining time",
            "value": o.time - o.usedtime,
            "color": "hsl(345, 70%, 50%)"
          },
        ]

        return(
              <div key={i} style={styles.party}>
              <div style={styles.ex} onClick={()=>triggerModal()}>
              X
              </div>
              <div style={styles.player}>
              {o.hash} <div style={styles.greendot}></div>
              </div>

        <ResponsivePie
        data={piedata}
        margin={{
            "top": 40,
            "right": 80,
            "bottom": 80,
            "left": 80
        }}
        innerRadius={0.5}
        padAngle={0.7}
        cornerRadius={3}
        colors="nivo"
        colorBy="id"
        borderWidth={1}
        borderColor="inherit:darker(0.2)"
        radialLabelsSkipAngle={10}
        radialLabelsTextXOffset={6}
        radialLabelsTextColor="#333333"
        radialLabelsLinkOffset={0}
        radialLabelsLinkDiagonalLength={16}
        radialLabelsLinkHorizontalLength={24}
        radialLabelsLinkStrokeWidth={1}
        radialLabelsLinkColor="inherit"
        slicesLabelsSkipAngle={10}
        slicesLabelsTextColor="#333333"
        animate={true}
        motionStiffness={90}
        motionDamping={15}
        defs={[
            {
                "id": "dots",
                "type": "patternDots",
                "background": "inherit",
                "color": "rgba(255, 255, 255, 0.3)",
                "size": 4,
                "padding": 1,
                "stagger": true
            },
            {
                "id": "lines",
                "type": "patternLines",
                "background": "inherit",
                "color": "rgba(255, 255, 255, 0.3)",
                "rotation": -45,
                "lineWidth": 6,
                "spacing": 10
            }
        ]}
        fill={[
            {
                "match": {
                    "id": "ruby"
                },
                "id": "dots"
            },
            {
                "match": {
                    "id": "c"
                },
                "id": "dots"
            },
            {
                "match": {
                    "id": "go"
                },
                "id": "dots"
            },
            {
                "match": {
                    "id": "python"
                },
                "id": "dots"
            },
            {
                "match": {
                    "id": "scala"
                },
                "id": "lines"
            },
            {
                "match": {
                    "id": "lisp"
                },
                "id": "lines"
            },
            {
                "match": {
                    "id": "elixir"
                },
                "id": "lines"
            },
            {
                "match": {
                    "id": "javascript"
                },
                "id": "lines"
            }
        ]}
        legends={[
            {
                "anchor": "bottom",
                "direction": "row",
                "translateY": 56,
                "itemWidth": 100,
                "itemHeight": 18,
                "itemTextColor": "#999",
                "symbolSize": 18,
                "symbolShape": "circle",
                "effects": [
                    {
                        "on": "hover",
                        "style": {
                            "itemTextColor": "#000"
                        }
                    }
                ]
            }
        ]}
    />
                <div style={styles.dataCount}>
                {o.data}
                </div>
                <div style={styles.timeCount}>
                {(o.time - o.usedtime)/1000} seconds left
                </div>
              </div>
              )
              })
      }
        </div>

        <div style={styles.consoleEnvelope}>
        <div style={{textAlign:'center', color:'#000000b1'}}>
        <h4>Connection Log</h4>
        </div>
       { history && history.map((o,i)=>{

        return(<div key={i}>
        <div key={i} style={styles.history}>
        <u>{o.hash}</u> on {o.connectedAt} <br/> <b>{o.payment} MIOTA</b>
        <IotaLogo />
        </div>
        
          {o.messages.map((o,i)=>{
            console.log(o)
             return (<div style={styles.messages}>
              {o}
             </div>)
             })
           }

          {/* <input value={this.state.text} 
            onChange={(e)=>this.setState({text:e.target.value})}
          />*/}

        </div>

        )
        })
      }
        
        </div>


        <div
        className={!this.props.showWallet ? "iota-wallet" : "iota-wallet wallet-center"}>
          <IotaProvider>
            <Wallet />
          </IotaProvider>
        </div>

      </div>
    );
  }
}

const styles = {
  messages:{
    padding: 10,
    color: 'black'
  },
  device: {
    background:'#fff',
  },
  devicesEnvelope: {
    marginLeft:10,
    width:'60%',
    fontSize:20,
    height:'100%',
    color:'#000',
    display:'inline-block',
    background:'#000000b1',
    borderRadius:4,
  },
  consoleEnvelope: {
    verticalAlign:'top',
    marginLeft:10,
    height:'100%',
    background:'#eeeeeeb1',
    width:'34%',
    display:'inline-block',
    borderRadius:4,
  },
  dataCount: {
    position: 'absolute',
    right:5,
    bottom:5,
  },
  timeCount: {
    position: 'absolute',
    left:5,
    bottom:5,
  },
  circle: {
    position:'absolute',
    color:'#fff',
    left:4,
    top:4,
    borderRadius:20,
    background:'#000000b1',
    width: 20,
    height: 20
  },
  separator: {
    display:'inline-block',
    marginLeft:5,
    width: 4,
    height:18,
    background: '#000000b1'
  },
  ex: {
    float:'right',
    color:'#fff',
    textAlign:'center',
    cursor:'pointer',
    borderRadius:20,
    background:'#000000b1',
    width: 30,
    height: 30
  },
  greendot:{
    display:'inline-block',
    color:'green',
    borderRadius:20,
    background:'#01FF70',
    width: 12,
    height: 12
  },
  party: {
    display:'inline-block',
    overflow: 'visible',
    verticalAlign:'middle',
    position:'relative',
    borderRadius: 4,
    width:'calc(100% - 34px)',
    height:300,
    padding:5,
    margin:20,
    marginRight:0,
    marginTop:0,
    background: '#ffffffb1'
  },
  history: {
    background:'#000000',
    wordWrap: 'normal',
    verticalAlign:'middle',
    position:'relative',
    // borderRadius: 4,
    height:80,
    padding:20,
    // margin:20,
    color: '#ffffffb1'
  },
  transactionEnvelope: {

  },
  player: {
    display:'inline-block',
  }
}



