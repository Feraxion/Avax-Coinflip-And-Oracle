// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface InterfaceForOracle{
    function newOracleRequest(bool _guess,uint _betIndex,address user) external;
}

contract CoinFlip is Ownable{

    uint[] betAmounts;
    uint trueGuessCount;
    uint totalRoll;
    address oracleAddress;

    mapping(address => uint256) public consecutiveWins;
    mapping(uint => uint) private rewardAmounts;

    
    constructor(){
        betAmounts.push(51750000000000000);
        rewardAmounts[betAmounts[0]] = 100000000000000000;
        betAmounts.push(103500000000000000);
        rewardAmounts[betAmounts[1]] = 200000000000000000;
        betAmounts.push(258750000000000000);
        rewardAmounts[betAmounts[2]] = 500000000000000000;
        betAmounts.push(517500000000000000);
        rewardAmounts[betAmounts[3]] = 1000000000000000000;
        betAmounts.push(1035000000000000000);
        rewardAmounts[betAmounts[4]] = 2000000000000000000;
        betAmounts.push(2070000000000000000);
        rewardAmounts[betAmounts[5]] = 4000000000000000000;

    }

    

    //Emit event for web3
    event flipResult (bool _flipResult,uint _winStreak);



    function randomCheck(uint _randomByAPI) private returns(bool) {

        bool randomFlip;
        totalRoll += 1;

        uint randomC = _randomByAPI;

        if(randomC < 50){ 
             randomFlip = true;
        }else{
             randomFlip = false;
        }

        return randomFlip; 
    }

    function flipRequest(bool _guess,uint _betIndex) public payable {      
        require(address(this).balance > rewardAmounts[betAmounts[_betIndex]],"Contract does not have enough avax in bank to process this");
        //require(msg.value > 0,"No avax attached to transaction request");
        require(msg.value == betAmounts[_betIndex],"Wrong amount of avax for this option");

        InterfaceForOracle(oracleAddress).newOracleRequest(_guess, _betIndex,msg.sender);
    }

    function completeFlip(bool _guess,uint _betIndex,address _user,uint _randomByAPI) external{
      require(msg.sender == oracleAddress,"Only our Oracle can call this function");

       if(_guess == randomCheck(_randomByAPI)){
            uint payout = rewardAmounts[betAmounts[_betIndex]];
            payable(_user).transfer(payout);
            consecutiveWins[_user] += 1;

            emit flipResult(true,consecutiveWins[_user]);
            trueGuessCount++;
        }else{

            consecutiveWins[_user] = 0;
            emit flipResult(false,0);
        }
    }
    
    receive() external payable {}

    function depositUsingParameter(uint256 deposit) public payable {  //deposit ETH using a parameter to test via Remix
        require(msg.value == deposit);
        deposit = msg.value;
    }

    function checkBetAmounts() public view onlyOwner returns(uint[] memory){
        return betAmounts;
    }

    function checkBetAmountsMapping(uint _betAmount) public view onlyOwner returns(uint){
        return rewardAmounts[_betAmount];
    }

    function setOracleAddress(address _oracleAddress) public  onlyOwner {
        oracleAddress = _oracleAddress;
    }

    function getOracleAddress() public view onlyOwner returns(address){
        return oracleAddress;
    }

    // Withdraw funds on demand
    function withdraw(uint amount) public onlyOwner{
        payable(msg.sender).transfer(amount);
    }

    //How many rolls done in total
    function check() public view returns(uint,uint){
      return (totalRoll,trueGuessCount);
    }

    // Add new option to end of array
    function addBetOption(uint _newBetAmount,uint _newBetPayout) public onlyOwner{
        betAmounts.push(_newBetAmount);
        rewardAmounts[betAmounts[betAmounts.length-1]] = _newBetPayout;

    }

    // Move the last element to the deleted spot.
    // Remove the last element.    
    function removeBetOption(uint _betArrayPosition) public onlyOwner returns(uint[] memory){
        require(_betArrayPosition < betAmounts.length);

        rewardAmounts[betAmounts[_betArrayPosition]] = 0;

        for (uint i = _betArrayPosition; i<betAmounts.length-1; i++){
            betAmounts[i] = betAmounts[i+1];
        }
        betAmounts.pop();
        return betAmounts;
    }

}

