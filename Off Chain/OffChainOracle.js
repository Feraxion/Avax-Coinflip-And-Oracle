var Web3 = require('web3');
const axios = require('axios').default;
require("dotenv").config();

const fs = require('fs')

path = require('path'),    
filePath = path.join("./", 'errorLog.txt');

// const content = ''
// fs.writeFileSync('./errorLog.txt', content + `\n`, "UTF-8",{'flags': 'a+'}, err => {
//   if (err) {
//     console.error(err)
//     return
//   }
//   //file written successfully
// })

var options = {
  reconnect: {
      auto: true,
      delay: 10000, // ms
      maxAttempts: 5,
      onTimeout: false
  }
};

const web3 = new Web3(process.env.WEB3_PROVIDER_ADDRESS,options); // WSS(WEBSOCKET) PROVIDER 

const abi = JSON.parse(process.env.ABI);
const cfAbi = JSON.parse(process.env.CFABI); // Coinflip Contract ABI 
const cfAddress = "0x8c28887220EF40F08714B7EdC77E052f4FFcF57b"; // Coinflip Contract address 
const cfContract = new web3.eth.Contract(cfAbi, cfAddress);

const oracleAddress = "0x6D364cb8E23aF1494bb2cA73dfCE5eA3923267f5";
const contract = new web3.eth.Contract(abi, oracleAddress);
const newAccount = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY).address;



let waitTimer = 0;
let firstNonce = 0;
const txQueue = [];



// Add wallet to the list of wallets
function addToWallet(){
web3.eth.accounts.wallet.add({
    privateKey: process.env.PRIVATE_KEY,
    address: '0xaFBC116C600600b300e82AC91f8C84103Ff567b9'
});
}

//Make sure we have a nonce before we start listening
async function getNonce(){
  firstNonce = await web3.eth.getTransactionCount(newAccount);
}



addToWallet();
getNonce();

const finalizeRequest = (uint, seconduint)=>{
  console.log(`Finalizing request ${uint}`)
  let finalizeOptions = {from: newAccount,gas: '250000',nonce: firstNonce}; //Nonce is used to make sure we are not sending the same transaction twice

  firstNonce++;
  console.log(firstNonce)
  
  contract.methods.completeOracleRequest(uint,seconduint).send(finalizeOptions).then(console.log).catch((x)=>{
    let formatter = "Got an error while sending the tx with this unique ID: " + uint + "\n";
    console.log(formatter)
    fs.appendFileSync('./errorLog.txt', formatter, err => {
      if (err) {
        console.error(err)
        return
      }
       //done!
      })

      //setTimeout(process.exit(),5000)

    })//.catch(console.log)
    //console.log(newAccount)
 };

const listener = async ()=>{
    const eventSignature = "0xdd1908fee2f9c60f17ad7fd05be9ad7f215a15bb40a3f79a22a01e9d60485de7"; // Event signature

    console.log('Event signature listen about to start.');
   
    //console.log(`${startingBlock} is first block to begin listening`)

    const listenOptions = {
        //fromBlock: 		7934640, can enable this if you want to start listening from a specific block
        address: oracleAddress, //Only get events from specific addresses
        topics: [eventSignature]
    }
    
      web3.eth.subscribe('logs', listenOptions, async (err,event) => {
      if (!err) { 
        //Parsing the event data
       let uniqueID = parseInt(event.data.substring(2).slice(0,64), 16); //Unique ID of the request
       let userGuess = parseInt(event.data.substring(2).slice(65,128), 16); //User guess
       let betIndex = parseInt(event.data.substring(2).slice(129,192), 16); //Bet index
       let userWallet = "0x" + event.data.substring(218).slice(0,40); //User wallet address
      console.log(` İşlem:${uniqueID} + Oyuncu Tahmini: ${userGuess} + Bet seçeneği: ${betIndex} + Adres: ${userWallet}`); //Printing the event data in readable form
      //generateSignedIntegers(`Test`).then((x)=>finalizeRequest(uniqueID, x.result.random.data)).catch(console.log)

      //Since we are using an API with limited requests per second, we need to wait for a while before sending the next request
      txQueue.push({uniqueID,userGuess,betIndex,userWallet});
    
      
    }
    });
    console.log('Event signature listen started.');
};

listener();



let counter = 1;

function sendTransactionsFromQueue(){

  for (let i = 0; i < 4; i++) {
    if(txQueue[0] != undefined){
      console.log(`Now Processing flip request from ${txQueue[0].userWallet} Which is ${counter}th request this session and ${txQueue[0].uniqueID}th in total`)
      let __uniqueId = txQueue.shift().uniqueID
      
      generateSignedIntegers().then((x)=>finalizeRequest(__uniqueId, x.result.random.data)).catch(console.log);
      counter++;
    }else{break;}
  }
  console.log(`No tx in queue`);
}


setInterval(sendTransactionsFromQueue, 1000);

function timeoutProtector(){

   cfContract.methods.check().call().then((x) => {

     console.log("total flip and trueguess count: " + x[0] +" and "+ x[1]);
   }).catch(process.exit())
}

//timeoutProtector()

//setInterval(timeoutProtector, 600000);

function getRandomNumber(){
    let randomNumber = Math.floor(Math.random() * 100);
    console.log(`Gelen Random:${randomNumber}`)
    return randomNumber;
}

//getRandomNumber();

async function makeRequest (method, params = {}) {
    const resp = await axios({
        method: 'POST',
        url: "https://api.random.org/json-rpc/4/invoke",
        data: JSON.stringify({
            jsonrpc: "2.0",
            method,
            params,
            id: 1
        }),
        headers: {'Content-Type': 'application/json; charset=utf-8'}
    })
    
    return resp.data
};

//Request a random number from random.org API between 0 and 99
async function generateSignedIntegers(userData = null) {
        let data = {
            n: 1,
            min:0,
            max: 99,
            apiKey: `${process.env.RANDOM_API_KEY}`,
        }
        data.userData = userData 
        return makeRequest(`generateSignedIntegers`, data)
    
};


const sleep = (ms) =>
  new Promise(resolve => setTimeout(resolve, ms));

const timeoutCounter = async() => {
  await sleep(1111);
  if(waitTimer>0){
    waitTimer = waitTimer - 1;
  }
};

