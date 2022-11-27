// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IRockPaperScissors {
    function login() external payable returns (string memory);
    function commitTurn(bytes32 hash) external returns (bool);
    function revealTurn(uint256 turn, uint256 randomNumber) external returns (bool);
    function whoWon() external returns (string memory);
    function resetGame() external returns (bool);
    function getCurrentGameStageString() external view returns (string memory);
}

contract OnlyRockPlayer {

    address gameContractAddress = 0x6189CBf579f1B5492de6a0899d1aB6142a1570F8;
    IRockPaperScissors gameContract = IRockPaperScissors(gameContractAddress);

    receive() external payable {}

    fallback() external payable {}

    function login() public payable returns (string memory) {
        return gameContract.login{value: 1 wei}();
    }

    function commitRock() public returns (bool) {
        return gameContract.commitTurn(0xf65ed4c552560d8edf75e5e940647efd2331418e315a7ef6beb8e37eaa417e94);
    }

    function revealRock() public returns (bool) {
        return gameContract.revealTurn(1, 343054099);
    }

    function whoWon() public returns (string memory) {
        return gameContract.whoWon();
    }
    
    function resetGame() public returns (bool) {
        return gameContract.resetGame();
    }

    function getCurrentGameStageString() public view returns (string memory) {
        return gameContract.getCurrentGameStageString();
    }

    function getPlayerContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}