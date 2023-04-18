async function main() {

	const [owner] = await ethers.getSigners()

	console.log('Deploying contracts with the account:', owner.address)

	console.log('Account balance:', ethers.utils.formatUnits(await owner.getBalance()))

	const Amulets = await ethers.getContractFactory('BLXMAvatarAmulets')
	const amulets = await upgrades.deployProxy(Amulets, ['http://127.0.0.1:8080/ipfs/amulets/{id}.json'], { kind: 'uups', initializer: 'initialize' })

	const Avatars = await ethers.getContractFactory('NFTicketAvatar')
	const avatars = await upgrades.deployProxy(Avatars, ['NFTicketAvatar', 'BLXMNFT', 'http://127.0.0.1:8080/ipfs/', amulets.address], { kind: 'uups', initializer: 'initialize' })
	// const cc = await upgrades.upgradeProxy('0x0', CC)

	await amulets.setAvatarsContractAddress(avatars.address)

	console.log('BLXMAvatarAmulets address:', amulets.address)
	console.log('NFTicketAvatar address:', avatars.address)

}

main()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})