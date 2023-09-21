import chain from './chain.json' assert { type: 'json' }
import { configureChains, createClient, getProvider, getContract, getAccount, watchAccount, fetchSigner } from '@wagmi/core'
import { hardhat } from '@wagmi/core/chains'
import { EthereumClient, w3mConnectors, w3mProvider } from '@web3modal/ethereum'
import { Web3Modal } from '@web3modal/html'

/* const volta = {
	id: 73799,
	name: 'Volta',
	network: 'volta',
	nativeCurrency: {
		decimals: 18,
		name: 'Volta Token',
		symbol: 'VT'
	},
	rpcUrls: {
		public: { http: ['https://volta-rpc.energyweb.org/'] },
		default: { http: ['https://volta-rpc.energyweb.org/'] },
	}
} */

const btn_connect = document.getElementById('connect')
btn_connect.addEventListener('click', connect)

const btn_mint = document.getElementById('mint')
btn_mint.addEventListener('click', mint)

let tokens = []

const inventory = document.querySelector('#inventory .wrapper')
const inventory_list_wrapper = inventory.querySelector('#token_list')
const inventory_list_viewport = inventory_list_wrapper.querySelector('.viewport')
const inventory_list = inventory_list_wrapper.querySelector('ul')
const inventory_prev = inventory_list_wrapper.querySelector('.prev')
const inventory_next = inventory_list_wrapper.querySelector('.next')
const inventory_msg = inventory.querySelector('.msg')

const web3modal = setup_web3modal([hardhat])

const provider = getProvider({ chainId: chain.chain_id })

const avatars_contract = getContract({
	address: chain.contracts.avatars.addr,
	abi: chain.contracts.avatars.abi,
	signerOrProvider: provider
})

let account = getAccount()
if (!account.isConnected) {
	check_minting_is_open()
	update_inventory()
}
watchAccount(new_account => {
	account = new_account
	if (account.isConnected) {
		btn_connect.textContent = account.address.slice(0, 6) + '…' + account.address.slice(-4)
	} else {
		btn_connect.textContent = 'Connect Wallet'
	}
	check_minting_is_open()
	update_inventory()
})

function setup_web3modal(chains) {

	const projectId = chain.walletconnect.project_id

	const { provider, webSocketProvider } = configureChains(chains, [
		w3mProvider({ projectId })
	])
	const wagmi_client = createClient({
		autoConnect: true,
		connectors: w3mConnectors({ projectId, version: 2, chains }),
		provider,
		webSocketProvider
	})
	const ethereum_client = new EthereumClient(wagmi_client, chains)
	return new Web3Modal({
		projectId,
		/* mobileWallets: [{
			id: 'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96',
			name: 'MetaMask',
			links: {
				native: 'metamask:',
				universal: 'https://metamask.app.link',
			},
		}], */
		themeMode: 'light',
		themeVariables: {
			'--w3m-background-color': '#4C986D',
			'--w3m-accent-color': '#4C986D'
		}
	}, ethereum_client)

}

async function connect(e) {
	web3modal.openModal('ConnectWallet')
}

async function mint(e) {

	if (!account.isConnected) {
		await web3modal.openModal()
		return
	}

	btn_mint.classList.add('loading')

	try {
		const signer = await fetchSigner()
		const cost = await avatars_contract.cost()
		const tx = await avatars_contract.connect(signer).mint(account.address, 1, { value: cost })
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

	if (account.isConnected) {
		tokens = await avatars_contract.connect(provider).tokensOfOwner(account.address)
	}

	if (tokens.length) {
		inventory.className = 'has_tokens'
		if (tokens.length > 1) inventory.classList.add('multiple')
		tokens.forEach(add_token_to_inventory)
	} else if (account.isConnected) {
		inventory.className = 'empty'
		inventory_msg.innerHTML = `You have no avatars in your current wallet:<br><code>${account.address}</code>`
		inventory_msg.removeAttribute('hidden')
	} else {
		inventory.className = 'locked'
		inventory_msg.innerHTML = '<b>Connect wallet</b><br>to view your inventory'
	}

	inventory.classList.remove('loading')

	update_arrows_state()
}

async function add_token_to_inventory(token_id) {
	const li = document.createElement('li')
	// const uri = await avatars_contract.connect(provider).tokenURI(token_id)
	// const metadata = await (await fetch(uri)).json()
	// li.innerHTML = `<img src="${metadata.image}" width="480" height="480">`
	li.innerHTML = `<img src="/img/avatars/${Math.ceil(Math.random() * 4)}.jpg" width="480" height="480">`
	inventory_list.appendChild(li)
}

async function check_minting_is_open() {
	const total_supply = await avatars_contract.connect(provider).totalSupply()
	const max_supply = await avatars_contract.connect(provider).maxSupply()
	if (total_supply == max_supply) {
		btn_mint.disabled = true
		btn_mint.textContent = 'All tokens are minted.'
	}
}

// inventory scroller:

let curr_inventory_pos = 0

async function scroll_inventory(dir) {
	const inventory_vp_style = getComputedStyle(inventory_list_viewport)
	const inventory_scroll_step = parseInt(inventory_vp_style['width']) - parseInt(inventory_vp_style['border-left-width']) - parseInt(inventory_vp_style['border-right-width'])
	curr_inventory_pos += dir == 'right' ? 1 : -1
	const offset = inventory_scroll_step * curr_inventory_pos * -1
	inventory_list.style.transform = `translateX(${offset}px)`
	update_arrows_state()
}

function update_arrows_state() {
	inventory_prev.disabled = curr_inventory_pos == 0
	inventory_next.disabled = curr_inventory_pos == (tokens.length - 1)
}

inventory_prev.addEventListener('click', e => scroll_inventory('left'))
inventory_next.addEventListener('click', e => scroll_inventory('right'))