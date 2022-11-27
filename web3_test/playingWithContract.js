async function main() {
	require("dotenv").config();

	const RockPaperScissors_ABI = require('./ABI_RockPaperScissors.json');
	const OnlyRockPlayer_ABI = require('./ABI_OnlyRockPlayer.json');

	const Web3 = require('web3');
	var web3 = new Web3(new Web3.providers.HttpProvider(`https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`));
	console.log(await web3.eth.getBalance(process.env.MY_GOERLI_ADDRESS));
	const gameContract = new web3.eth.Contract(RockPaperScissors_ABI, process.env.RockPaperScissors_ADDRESS);
	const onlyRockPlayerContract = new web3.eth.Contract(OnlyRockPlayer_ABI, process.env.OnlyRockPlayer_ADDRESS);

	const signer = web3.eth.accounts.privateKeyToAccount(process.env.SIGNER_PRIVATE_KEY);
	web3.eth.accounts.wallet.add(signer);

	console.log("\n1. logging part");
	let tx = gameContract.methods.login();
	let receipt = await tx.send({ from: signer.address, gas: 300000, value: 1 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });
	tx = onlyRockPlayerContract.methods.login();
	receipt = await tx.send({ from: signer.address, gas: 300000, value: 1 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });

	console.log("\n2. commit part");
	tx = gameContract.methods.commitTurn("0x11a33a5b89a9d1a8d59691307999b82e1f6994d52fb968ead61100fa5f150b35");
	receipt = await tx.send({ from: signer.address, gas: 300000 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });
	tx = onlyRockPlayerContract.methods.commitRock();
	receipt = await tx.send({ from: signer.address, gas: 300000 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });

	console.log("\n3. reveal part");
	tx = gameContract.methods.revealTurn(2, 779317318);
	receipt = await tx.send({ from: signer.address, gas: 300000 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });
	tx = onlyRockPlayerContract.methods.revealRock();
	receipt = await tx.send({ from: signer.address, gas: 300000 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });

	console.log("\n4. end part");
	tx = gameContract.methods.whoWon();
	receipt = await tx.send({ from: signer.address, gas: 300000 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });
	tx = onlyRockPlayerContract.methods.whoWon();
	receipt = await tx.send({ from: signer.address, gas: 300000 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });

	console.log("\nOnlyRockPlayer contract balance:");
	onlyRockPlayerBalance = await onlyRockPlayerContract.methods.getPlayerContractBalance().call();
	console.log("OnlyRockPlayer balance == 2: " + (onlyRockPlayerBalance == 2));

	console.log("\n5. reset game part");
	tx = gameContract.methods.resetGame();
	receipt = await tx.send({ from: signer.address, gas: 300000 }).once("transactionHash" , (txHash) => { console.info("mining transaction...", txHash) });
}

main();