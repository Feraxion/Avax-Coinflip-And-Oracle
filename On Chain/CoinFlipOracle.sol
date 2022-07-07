// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface InterfaceForCoinflip{
    function completeFlip(bool _guess,uint _betIndex,address _user,uint _randomByAPI) external;
}

contract CoinFlipOracle is Ownable{

    Request[] requests; 
    uint uniqueID; 
    address coinflipContractAddress;

    struct Request { 
        uint _uniqueID;                            
        bool playerGuess;                 
        uint betOption;       
        address flipUser;     
        uint randomByAPI;   
    }

    event oracleRequest (uint _uniqueID,bool _flipGuess,uint _betIndex,address _user);

    function newOracleRequest(bool _guess,uint _betIndex,address _user) public {      
        require(msg.sender == coinflipContractAddress,"Only coinflip contract can call this function");
       
        requests.push(Request(uniqueID,_guess,_betIndex,_user,0));
        
        emit oracleRequest(uniqueID, _guess,_betIndex,_user);
        uniqueID++;    
    }

    function completeOracleRequest(uint _uniqueID,uint _randomByAPI) public onlyOwner {      

      Request storage R = requests[_uniqueID];
        
      R.randomByAPI = _randomByAPI;

      InterfaceForCoinflip(coinflipContractAddress).completeFlip(R.playerGuess,R.betOption, R.flipUser,_randomByAPI);
        
    }

    function depositUsingParameter(uint256 deposit) public payable {  //deposit ETH using a parameter
      require(msg.value == deposit);
      deposit = msg.value;
    }

    function setCoinflipContractAddress(address _address)public  onlyOwner{
        coinflipContractAddress = _address;
    }

    function getCoinflipContractAddress() public view onlyOwner returns(address){
        return coinflipContractAddress;
    }

    function getRequest(uint _index) public view onlyOwner returns(Request memory){
        return requests[_index];
    }

    receive() external payable {}

}

   