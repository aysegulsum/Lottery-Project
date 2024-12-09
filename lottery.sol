// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;
/*
interface ITicketFeeOracle {
    function getTicketFee() external view returns (uint);
    }
*/
contract Lottery{

    address payable admin; //deployer
    address payable[] public users; // users array
    address payable public winner; //winner of the lottery
    bool public winnerExist;

    uint public ticketFee;
    uint private purchaseEndTime;
    uint private decideEndTime; 
    uint256 private finalRandomNumber;  

    mapping (address => bytes32) public userRNHashes; // hashes submitted by users
    mapping (address => uint) public revealedNumbers; // numbers revealed by users
   

    constructor(uint _purchaseDuration, uint _decideDuration){
        admin = payable(msg.sender);
       // ITicketFeeOracle  feeOracle = ITicketFeeOracle(0xAD39623a8Cd97185755310Cec8AFDb19Fe330D5A);
       //ticketFee = feeOracle.getTicketFee();
        ticketFee = 7 ether;
        purchaseEndTime = block.timestamp + _purchaseDuration;
        decideEndTime = purchaseEndTime + _decideDuration;
    }
  
       // contracts balance
    function getBalance() view public returns(uint){
        return address(this).balance; 
    }
    // handle all ticket demands
    function purchaseTicket(bytes32 hash) external payable {
        require(msg.sender != admin, "Owner cannot play!");
        require(block.timestamp < purchaseEndTime, "Lottery contribution period is over!");
        require(msg.value >= ticketFee, "Ticket fee is insufficient");
        require(userRNHashes[msg.sender] == 0, "Already purchased a ticket");

        //The excess must be refunded back
        if (msg.value > ticketFee) {
        uint excess = msg.value - ticketFee;
        payable(msg.sender).transfer(excess);
        }

        userRNHashes[msg.sender] = hash;
        users.push(payable(msg.sender));
    }

    //checks the hash 
    function hashChecker(address _sender, uint32 _number) view  internal returns(bool){
        // avoid the hash of same random number using concatanation hash
        bytes memory combine = abi.encodePacked(_sender, _number);
        bytes32 calculatedHash = keccak256(combine);
        // conpare the pre-hash and hash of user address-revealed number
        return userRNHashes[msg.sender] == calculatedHash;
    }
 
    // reveal the random number
    function revealNumber(uint32 number) external {
        require(block.timestamp > purchaseEndTime, "Lottery reveal period not yet started");
        require(block.timestamp < decideEndTime, "Lottery reveal period is over!");
        require(userRNHashes[msg.sender] != 0, "No hash submitted");
        require(revealedNumbers[msg.sender] == 0, "Already revealed");
        require(hashChecker(msg.sender, number), "You aren't revealing the correct number!");
        revealedNumbers[msg.sender] = number;
    }
    // decide the winner after reaching reveal time
    function pickWinner() external {
        require( admin == msg.sender, "You are not the owner!");
        require( !winnerExist, "Winner already choosed.");
        require(block.timestamp >= decideEndTime, "Decide stage has not ended!");
        // take xor of all revealed numbers 
        finalRandomNumber = revealedNumbers[users[0]];
        for (uint i = 1; i < users.length; i++) {
            finalRandomNumber ^= revealedNumbers[users[i]];
        }
        winner = users[finalRandomNumber % users.length];
        winnerExist = true;
    }
    function claimPrize() external {
        require(msg.sender == winner, "You are not the winner");
        winner.transfer(getBalance());
        //selfdestruct(payable(winner));// ide not support to destruct
    }

    function amIWinner() view public returns (string memory) {
        require(block.timestamp >= decideEndTime, "Decide stage has not ended");
        require(winnerExist, "The Winner not announced yet!");

        if (msg.sender == winner) {
            return "Congratulations, you are the Winner!";
        } else {
            return "Unfortunately, you are not the winner.";
        }
    }

    function learnStage() view public returns (string memory stage, uint currentTime, uint endTime){
        if (block.timestamp < purchaseEndTime) {
            return ("The lottery is still open for purchasing", block.timestamp, purchaseEndTime);
            } else if (block.timestamp < decideEndTime) {
            return ("The lottery is still open for revealing" , block.timestamp, decideEndTime);
            }
            else {
            return ("The lottery is over" , block.timestamp, decideEndTime);
            }
    }
}
