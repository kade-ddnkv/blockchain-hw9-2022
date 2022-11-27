// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract RockPaperScissors {

    // +----------------------------------------------------------------------------+
    // Всякие переменные.

    uint256 constant public BET = 1 wei;

    enum Turn {None, Rock, Paper, Scissors}

    // Для логина игроков.
    uint256 private playersCount = 0;
    mapping(address => uint256) private players;
    mapping(uint256 => address) private addresses;

    // Для отправки хэша от сделанного выбора. 
    uint256 private hashesCount = 0;
    mapping(address => bytes32) private hashes;

    // Для подтверждения сделанного выбора и хэша.
    uint256 private turnsCount = 0;
    mapping(address => Turn) private turns;

    // Баланс игроков для выдачи выигрыша.
    mapping(address => uint256) private balances;

    // Запись выигравшего, чтобы не вычислять несколько раз.
    bool private winnerFound = false;
    address private winner;

    mapping(uint256 => string) stageStrings;

    constructor() {
        stageStrings[0] = "players logging";
        stageStrings[1] = "commiting turns";
        stageStrings[2] = "revealing turns";
        stageStrings[3] = "game end";
    }


    // +----------------------------------------------------------------------------+
    // События.

    event PlayerLogged(address player, uint256 playerNumber);

    event PlayerCommited(address player, bytes32 hash);

    event PlayerRevealed(address player, uint256 turn, uint256 randomNumber);

    event PlayerNotPassedReveal(address player);

    event GameEnded(address winner);

    event GameResetted();


    // +----------------------------------------------------------------------------+
    // Несколько модификаторов.
    // Направлены в основном на то, чтобы не давать игроку сделать действие из другой стадии игры.
    // И не давать изменять/повторять уже сделанные действия. 

    modifier notLogged() {
        require(players[msg.sender] == 0, "you are already logged in game");
        _;
    }

    modifier logged() {
        require(players[msg.sender] != 0, "you are not in game");
        _;
    }

    modifier validBet() {
        require(msg.value == BET, "incorrect bet. look at the contract variable BET");
        _;
    }

    modifier loginStage() {
        require(getCurrentGameStageUint() == 0, "you can't do this in current game stage");
        _;
    }

    modifier stageCommit() {
        require(getCurrentGameStageUint() == 1, "you can't do this in current game stage");
        require(playersCount == 2, "not everyone has logged");
        require(hashes[msg.sender] == 0, "you has already commited");
        _;
    }

    modifier stageReveal() {
        require(getCurrentGameStageUint() == 2, "you can't do this in current game stage");
        require(hashesCount == 2, "not everyone has commited");
        require(turns[msg.sender] == Turn.None, "you has already revealed");
        _;
    }

    modifier stageEnd() {
        require(getCurrentGameStageUint() == 3, "you can't do this in current game stage");
        require(turnsCount == 2, "not everyone has revealed");
        _;
    }

    modifier zeroBalances() {
        require(balances[addresses[1]] == 0 && balances[addresses[2]] == 0, "not everyone has claimed their money");
        _;
    }


    // +----------------------------------------------------------------------------+
    // Основные функции.

    // Используется для регистрации в системе каждого из двух игроков.
    function login() public payable notLogged loginStage validBet returns (string memory) {
        if (playersCount == 2) {
            return "game has already started";
        }
        playersCount++;
        players[msg.sender] = playersCount;
        addresses[playersCount] = msg.sender;
        emit PlayerLogged(msg.sender, playersCount);
        return string.concat("you are the player number ", Strings.toString(playersCount));
    }

    // Сохраняет хэш хода от каждого из игроков.
    function commitTurn(bytes32 hash) public logged stageCommit returns (bool) {
        hashes[msg.sender] = hash;
        hashesCount++;
        emit PlayerCommited(msg.sender, hash);
        return true;
    }

    // Сохраняет и проверяет настоящий ход с хэшем от каждого из игроков.
    function revealTurn(uint256 turn, uint256 randomNumber) public logged stageReveal returns (bool) {
        turns[msg.sender] = stringTurnToEnum(turn);
        turnsCount++;
        emit PlayerRevealed(msg.sender, turn, randomNumber);
        string memory strigified = string.concat(Strings.toString(turn), Strings.toString(randomNumber));
        if (keccak256(abi.encodePacked(strigified)) == hashes[msg.sender]) {
            return true;
        }
        turns[msg.sender] = Turn.None;
        emit PlayerNotPassedReveal(msg.sender);
        return false;
    }

    // Переводит численное значение хода (1,2,3) в enum.
    function stringTurnToEnum(uint256 turn) private pure returns (Turn) {
        if (turn >= 1 && turn <= 3) {
            return Turn(turn);
        }
        return Turn.None;
    }

    // Вычисляет победителя, переводит деньги победителю.
    function whoWon() public logged stageEnd returns (string memory) {
        if (winnerFound == false) {
            calcWinner();
            calcBalances();
        }
        paySender();
        if (winner == address(0)) {
            return "it's a draw";
        }
        if (winner == msg.sender) {
            return "you won";
        }
        return "you lose";
    }

    // Вычисляет победителя в игре.
    // Как ни печально, только ради этого метода мне пришлось завести словарь addresses.
    // Зато код довольно простой получился.
    function calcWinner() private {
        Turn first = turns[addresses[1]];
        Turn second = turns[addresses[2]];
        if (first == second) {
            winner = address(0);
        } else if (uint256(first) + uint256(second) == 4) {
            if (first == Turn.Rock) {
                winner = addresses[1];
            } else {
                winner = addresses[2];
            }
        } else if (uint256(first) < uint256(second)) {
            winner = addresses[2];
        } else {
            winner = addresses[1];
        }
        winnerFound = true;
        emit GameEnded(winner);
    }

    // Вычисляет баланс каждого игрока.
    // Использовать только после определения победителя.
    function calcBalances() private {
        if (winner == address(0)) {
            balances[addresses[1]] = BET;
            balances[addresses[2]] = BET;
        } else {
            balances[winner] = BET * 2;
        }
    }

    // Выплачивает выигравшему (выигравшим) деньги из баланса контракта в соответствии со словарем balances.
    function paySender() private {
        if (balances[msg.sender] != 0) {
            (bool sent, bytes memory data) = payable(msg.sender).call{value: balances[msg.sender]}("");
            require(sent, "failed to send ether");
            balances[msg.sender] = 0;
        }
    }

    // Возвращает текущий баланс игрока.
    // Возвращает не 0 только после определения победителя и перед переводом денег.
    function getMyBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    // Возвращает текущий баланс контракта.
    // Пока это может быть либо 0, либо 1 * BET, либо 2 * BET.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Возвращает текущую стадию игры в виде числа.
    function getCurrentGameStageUint() public view returns (uint256) {
        if (playersCount != 2) {
            return 0;
        }
        if (hashesCount != 2) {
            return 1;
        }
        if (turnsCount != 2) {
            return 2;
        }
        return 3;
    }

    // Возвращает текущую стадию игры в виде строки.
    function getCurrentGameStageString() public view returns (string memory) {
        return stageStrings[getCurrentGameStageUint()];
    }

    // Перезагружает игру.
    function resetGame() public stageEnd zeroBalances returns (bool) {
        playersCount = 0;
        hashesCount = 0;
        turnsCount = 0;
        for (uint i = 1; i <= 2; i++) {
            players[addresses[i]] = 0;
            hashes[addresses[i]] = 0;
            turns[addresses[i]] = Turn.None;
            addresses[i] = address(0);
        }
        winnerFound = false;
        winner = address(0);
        emit GameResetted();
        return true;
    }

    function getPlayersAddresses() public view returns (address, address) {
        return (addresses[1], addresses[2]);
    }
} 