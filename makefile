-include .env

.PHONY: all install compile anvil help

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Network Arguments
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast  --via-ir
AVAX_FUJI_TESTNET_ARGS := --rpc-url $(RPC_URL_AVAX_FUJI) --private-key $(PRIVATE) --broadcast --via-ir -vvvv
ETH_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ETH_SEPOLIA) --private-key $(PRIVATE) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API) -vvvv
ARB_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ARB_SEPOLIA) --private-key $(PRIVATE) --broadcast --verify --verifier-url "https://api-sepolia.arbiscan.io/api" --etherscan-api-key $(ARBISCAN_API) -vvvv

# Main commands
all: clean remove install update build 

install:
	@echo "Installing libraries"
	@npm install
	@forge compile --via-ir

compile:
	@forge b --via-ir --sizes

anvil:
	@echo "Starting Anvil, remember to use another terminal to run tests"
	@anvil -m 'test test test test test test test test test test test junk' --steps-tracing

# Deployment commands
mock: mockToken mockTreasury mockEvvm

deployTestnet: 
	@echo "Deploying testnet"
	@forge script script/DeployTestnet.s.sol:DeployTestnet $(ARB_SEPOLIA_TESTNET_ARGS) -vvvv


mockToken:
	@echo "Deploying test Token Contracts in anvil local testnet"
	@forge script script/DeployTokenMock.s.sol:DeployTokenMock $(NETWORK_ARGS) -vvvvv

mockTreasury:
	@echo "Deploying test Treasury Contracts in anvil local testnet"
	@forge script script/DeployMockTreasury.s.sol:DeployMockTreasury $(NETWORK_ARGS) -vvvvv

mockEvvm:
	@echo "Deploying mate protocol in anvil local testnet"
	@forge script script/DeployMockEvvm.s.sol:DeployMockEvvm $(NETWORK_ARGS) -v

deployEvvmMock:
	@echo "Deploying test Contracts in ETH Sepolia testnet"
	@forge script script/DeployMockEvvm.s.sol:DeployMockEvvm $(ETH_SEPOLIA_TESTNET_ARGS)

deploySideChainEvvmMock:
	@echo "Deploying test Contract in AVAX Fuji testnet"
	@forge script script/DeployMockEvvm.s.sol:DeployMockEvvm $(AVAX_FUJI_TESTNET_ARGS)

deploySideChainMateNameServiceMock:
	@echo "Deploying test Contract in AVAX Fuji testnet"
	@forge script script/DeploySideChainMateNameServiceMock.s.sol:DeploySideChainMateNameServiceMock $(AVAX_FUJI_TESTNET_ARGS)

# Help command
help:
	@echo "-------------------------------------=Usage=-------------------------------------"
	@echo ""
	@echo "  make install -- Install dependencies and compile contracts"
	@echo "  make compile -- Compile contracts"
	@echo "  make anvil ---- Run Anvil (local testnet)"
	@echo ""
	@echo "-----------------------=Deployers for local testnet (Anvil)=----------------------"
	@echo ""
	@echo "  make mock --------- Deploy all mock contracts (Token, Treasury, EVVM)"
	@echo "  make mockToken ---- Deploy mock Token contract"
	@echo "  make mockTreasury - Deploy mock Treasury contract"
	@echo "  make mockEvvm ----- Deploy mock EVVM contract"
	@echo ""
	@echo "-----------------------=Deployers for test networks=----------------------"
	@echo ""
	@echo "  make deployEvvmMock --------------------- Deploy EVVM mock to Ethereum Sepolia testnet"
	@echo "  make deploySideChainEvvmMock ------------ Deploy EVVM mock to Avalanche Fuji testnet"
	@echo "  make deploySideChainMateNameServiceMock - Deploy MNS mock to Avalanche Fuji testnet"
	@echo ""
	@echo "-----------------------=Other commands=----------------------"
	@echo ""
	@echo "  make staticAnalysis --- Run static analysis and generate report"
	@echo ""
	@echo "---------------------------------------------------------------------------------"