async function main() {

	const [owner] = await ethers.getSigners()

	console.log('Deploying contracts with the account:', owner.address)

	console.log('Account balance:', ethers.utils.formatUnits(await owner.getBalance()))

	const NFTicketAvatar = await ethers.getContractFactory('NFTicketAvatar')
	const contract = await upgrades.deployProxy(NFTicketAvatar, ['NFTicketAvatar', 'BLXMNFT', 'http://localhost:8080/ipfs/'], { kind: 'uups', initializer: 'initialize' })
	// const contract = await upgrades.upgradeProxy('0x0', NFTicketAvatar)

	console.log('NFTicketAvatar address:', contract.address)

}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})