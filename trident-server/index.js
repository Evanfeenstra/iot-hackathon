const SerialPort = require('serialport')
var StringDecoder = require('string_decoder').StringDecoder;
const axios = require('axios')
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 80 });

wss.on('connection', function connection(ws) {
  console.log("WS CONNECTED")

SerialPort.list(function (err, results) {
  if (err)  {
    throw err;
  }
  console.log(results)
})

const port = new SerialPort('/dev/tty.SLAB_USBtoUART', {
  baudRate: 115200
})

port.on('open', function () {
  console.log('port opened');
});

port.on('data', function (data) {
  var decoder = new StringDecoder('utf8');
  var textChunk = decoder.write(data);
  console.log(textChunk)

  const msg = JSON.parse(textChunk)
  console.log(msg)

  if(msg.type==='REQUEST'){
    axios.post(
      'http://10.177.0.19:9191/payment',
      {
        from:msg.address,
        to:'GREKRLDLCIPAOVKGZYJCLEXMEMND9DLLWEPZBKBHVKVAQVOCFEGRDSTNGIKUPSIWEVGSXEOIHGKQWX9DDESIDNQLR9',
        amount:10,
        secret:'KLCTTSWE9EJPL9ZAVXAPBYW9SQSHMMTIKIWGZCG9SE9ITWXKAZLAVV9GZKZZLGI9DVOMCHNWC9XDTXZKN'
      }
    ).then(()=>{
      console.log("PAYMENT CONFIRMED")
      confirmPayment()
    })
    .catch(()=>{
      console.error("payment not confirmed")
      confirmPayment()
    })
  }

  if(msg.type==='MESSAGE'){
    console.log("MESSAGE:",msg.text)
    //console.log(WS)
    // WS.send(`{"type":"MESSAGE","text":"${msg.text}"}`,{},function(a,b,c){
    //   console.log('a',a,c)
    //   console.log('b',b)
    // });

    wss.clients.forEach(function each(client) {
      console.log("CLEINT",client.readyState,WebSocket.OPEN)
      if (client.readyState === WebSocket.OPEN) {
        console.log("HELOO?????")
        client.send(`{"type":"MESSAGE","text":"${msg.text}"}`);
      }
    });
  }

})


//let WS

  // console.log("DOES THIS WORK?")
  // WS = ws
  ws.on('message', function incoming(data) {
    port.write(data, function(err) {
      if (err) {
        return console.log('Error on write: ', err.message)
      }
      console.log('message written')
    })
  });


function confirmPayment(){
  //console.log(WS)
  ws.send('{"type":"CONFIRMED"}');
}

});

