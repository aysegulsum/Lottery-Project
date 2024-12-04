// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface ITicketFeeOracle {
    function getTicketFee() external view returns (uint);
    }

contract Lottery{

    address payable[] public users; // users array
    address payable admin; //deployer
    address payable public winner; //winner of the lottery

    uint public ticketFee;
    uint public purchaseEndTime;
    uint public decideEndTime;

    mapping (address => bytes32) public userRNHashes; // hashes submitted by users
    mapping (address => uint) public revealedNumbers; // numbers revealed by users
    uint256 public finalRandomNumber;
   

    constructor(uint _purchaseDuration, uint _decideDuration){
        admin = payable(msg.sender);
        ITicketFeeOracle  feeOracle = ITicketFeeOracle(0xAD39623a8Cd97185755310Cec8AFDb19Fe330D5A);
        ticketFee = feeOracle.getTicketFee();
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
        require(hash != bytes32(0), "Hash must be provided to buy a ticket");

        //The excess must be refunded back
        if (msg.value > ticketFee) {
        uint excess = msg.value - ticketFee;
        payable(msg.sender).transfer(excess);
        }

        userRNHashes[msg.sender] = hash;
        users.push(payable(msg.sender));
    }
    // reveal the random number
    function revealNumber(uint number) external {
        require(block.timestamp < decideEndTime, "Lottery reveal period is over!");
        require(userRNHashes[msg.sender] != 0, "No hash submitted");
        require(revealedNumbers[msg.sender] == 0, "Already revealed");
        require(userRNHashes[msg.sender] == keccak256(abi.encodePacked(number)), "You aren't revealing the correct number!");

        revealedNumbers[msg.sender] = number;
    }
    // decide the winner after reaching reveal time
    function pickWinner() external {
        require( admin == msg.sender, "You are not the owner");
        require(block.timestamp >= decideEndTime, "Decide stage has not ended");//????

        finalRandomNumber = revealedNumbers[users[0]];
        for (uint i = 1; i < users.length; i++) {
            finalRandomNumber ^= revealedNumbers[users[i]];
        }

        winner = users[finalRandomNumber % users.length];
    }
    function claimPrize() external {
        require(msg.sender == winner, "You are not the winner");
        winner.transfer(getBalance());

        // selfdestruct(payable(winner)); ide not support to destruct
    }

/*    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp,users.length)));

    }*/
}