import chain from './chain.json' assert { type: 'json' }
import { configureChains, createClient, getProvider, getContract, getAccount, watchAccount, fetchSigner } from '@wagmi/core'
import { hardhat } from '@wagmi/core/chains'
import { EthereumClient, modalConnectors, walletConnectProvider } from '@web3modal/ethereum'
import { Web3Modal } from '@web3modal/html'

const btn_mint = document.getElementById('mint')
btn_mint.addEventListener('click', mint)

const inventory = document.querySelector('#inventory .wrapper')
const inventory_list = inventory.querySelector('ul')
const inventory_msg = inventory.querySelector('.msg')

const web3modal = setup_web3modal([hardhat])

const provider = getProvider({ chainId: chain.chain_id })

const contract = getContract({
	address: chain.contract.addr,
	abi: chain.contract.abi,
	signerOrProvider: provider
})

let account = getAccount()
if (!account.isConnected) {
	update_inventory()
}
watchAccount(new_account => {
	account = new_account
	update_inventory()
})

function setup_web3modal(chains) {

	const { provider, webSocketProvider } = configureChains(chains, [
		walletConnectProvider({ projectId: chain.walletconnect.project_id })
	])
	const wagmi_client = createClient({
		autoConnect: true,
		connectors: modalConnectors({ chains }),
		provider,
		webSocketProvider
	})
	const ethereum_client = new EthereumClient(wagmi_client, chains)
	return new Web3Modal({
		projectId: chain.walletconnect.project_id,
		themeMode: 'light',
		themeColor: 'green'
	}, ethereum_client)

}

async function mint(e) {

	if (!account.isConnected) {
		await web3modal.openModal()
		return
	}

	btn_mint.classList.add('loading')

	try {
		const signer = await fetchSigner()
		const cost = await contract.cost()
		const tx = await contract.connect(signer).mint(account.address, 1, { value: cost })
		await tx.wait()
		update_inventory()
	} catch (e) {
		// rejected
	}

	btn_mint.classList.remove('loading')

}

async function update_inventory() {

	inventory.classList.add('loading')

	inventory_list.innerHTML = '' // empty the list

	let tokens = []

	if (account.isConnected) {
		tokens = await contract.connect(provider).tokensOfOwner(account.address)
	}

	if (tokens.length) {
		inventory_msg.setAttribute('hidden', '')
		tokens.forEach(add_token_to_inventory)
	} else if (account.isConnected) {
		inventory_msg.innerHTML = `You have no avatars in your current wallet:<br><code>${account.address}</code>`
		inventory_msg.removeAttribute('hidden')
	} else {
		inventory_msg.innerHTML = 'Connect wallet to view your inventory.'
		inventory_msg.removeAttribute('hidden')
	}

	inventory.classList.remove('loading')
}

function add_token_to_inventory(token_id) {
	const li = document.createElement('li')
	li.innerHTML = Number(token_id)
	inventory_list.appendChild(li)
}