-include .env

.PHONY: all install compile anvil help

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Network Arguments
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast  --via-ir
AVAX_FUJI_TESTNET_ARGS := --rpc-url $(RPC_URL_AVAX_FUJI) --private-key $(PRIVATE) --broadcast --via-ir -vvvv
ETH_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ETH_SEPOLIA) --private-key $(PRIVATE) --broadcast --via-ir -vvvv

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

# Test commands

## EVVM

### Unit tests

#### Correct Tests

unitTestCorrectEvvm:
	@echo "Running all EVVM unit correct tests"
	@forge test --match-contract unitTestCorrect_EVVM --summary --detailed --gas-report -vvv --show-progress 

unitTestCorrectEvvmPayNoMateStaking_async:
	@echo "Running NoMateStaking_async unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_payNoMateStaking_async.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmPayNoMateStaking_sync:
	@echo "Running NoMateStaking_sync unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_payNoMateStaking_sync.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmPayMateStaking_async:
	@echo "Running PayMateStaking_async unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_payMateStaking_async.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmPayMateStaking_sync:
	@echo "Running PayMateStaking_sync unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_payMateStaking_sync.t.sol --summary --detailed --gas-report -vvv --show-progress
	
unitTestCorrectEvvmPayMultiple:
	@echo "Running PayMultiple unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_payMultiple.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmDispersePaySync:
	@echo "Running DispersePaySync unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_dispersePay_sync.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmDispersePayAsync:
	@echo "Running DispersePayAsync unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_dispersePay_async.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmCaPay:
	@echo "Running CaPay unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_caPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmDisperseCaPay:
	@echo "Running DisperseCaPay unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_disperseCaPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmAdminFunctions:
	@echo "Running AdminFunctions unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEvvmProxy:
	@echo "Running EVVM proxy unit correct tests"
	@forge test --match-path test/unit/evvm/correct/unitTestCorrect_EVVM_proxy.t.sol --summary --detailed --gas-report -vvv --show-progress

#### Revert Tests

unitTestRevertEvvm:
	@echo "Running all EVVM unit revert tests"
	@forge test --match-contract unitTestRevert_EVVM --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmPayNoMateStaking_sync:
	@echo "Running NoMateStaking_sync unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_payNoMateStaking_sync.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmPayNoMateStaking_async:
	@echo "Running NoMateStaking_async unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_payNoMateStaking_async.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmPayMateStaking_sync:
	@echo "Running PayMateStaking_sync unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_payMateStaking_sync.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmPayMultiple_syncExecution:
	@echo "Running PayMultiple (sync execution) unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_payMultiple_syncExecution.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmPayMultiple_asyncExecution:
	@echo "Running PayMultiple (async execution) unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_payMultiple_asyncExecution.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmDispersePay_syncExecution:
	@echo "Running DispersePay (sync execution) unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_dispersePay_syncExecution.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmDispersePay_asyncExecution:
	@echo "Running DispersePay (async execution) unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_dispersePay_asyncExecution.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmCaPay:
	@echo "Running CaPay unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_caPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmDisperseCaPay:
	@echo "Running DisperseCaPay unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_disperseCaPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmAdminFunctions:
	@echo "Running AdminFunctions unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertEvvmProxy:
	@echo "Running EVVM proxy unit revert tests"
	@forge test --match-path test/unit/evvm/revert/unitTestRevert_EVVM_proxy.t.sol --summary --detailed --gas-report -vvv --show-progress

## SMate

### Unit tests

#### Correct Tests

unitTestCorrectSMate:
	@echo "Running all SMate unit correct tests"
	@forge test --match-contract unitTestCorrect_SMate --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectSMateGoldenStaking:
	@echo "Running GoldenStaking unit correct tests"
	@forge test --match-path test/unit/smate/correct/unitTestCorrect_SMate_goldenStaking.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectSMatePresaleStake_AsyncExecutionOnPay:
	@echo "Running PresaleStake (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/smate/correct/unitTestCorrect_SMate_presaleStake_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectSMatePresaleStake_SyncExecutionOnPay:
	@echo "Running PresaleStake (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/smate/correct/unitTestCorrect_SMate_presaleStake_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectSMateExternalStaking_AsyncExecutionOnPay:
	@echo "Running ExternalStaking (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/smate/correct/unitTestCorrect_SMate_externalStaking_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectSMateExternalStaking_SyncExecutionOnPay:
	@echo "Running ExternalStaking (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/smate/correct/unitTestCorrect_SMate_externalStaking_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectSMateAdminFunctions:
	@echo "Running AdminFunctions unit correct tests"
	@forge test --match-path test/unit/smate/correct/unitTestCorrect_SMate_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress

#### Revert Tests

unitTestRevertSMate:
	@echo "Running all SMate unit revert tests"
	@forge test --match-contract unitTestRevert_SMate --summary --detailed --gas-report -vvv --show-progress

unitTestRevertSMateGoldenStaking:
	@echo "Running GoldenStaking unit revert tests"
	@forge test --match-path test/unit/smate/revert/unitTestRevert_SMate_goldenStaking.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertSMatePresaleStake:
	@echo "Running PresaleStake unit revert tests"
	@forge test --match-path test/unit/smate/revert/unitTestRevert_SMate_presaleStake.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertSMateExternalStaking:
	@echo "Running ExternalStaking unit revert tests"
	@forge test --match-path test/unit/smate/revert/unitTestRevert_SMate_externalStaking.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestRevertSMateAdminFunctions:
	@echo "Running AdminFunctions unit revert tests"
	@forge test --match-path test/unit/smate/revert/unitTestRevert_SMate_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress


## Estimator

### Unit tests

#### Correct Tests

unitTestCorrectEstimator:
	@echo "Running all estimator unit correct tests"
	@forge test --match-contract unitTestCorrect_Estimator --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEstimatorNotifyNewEpoch:
	@echo "Running estimator notifyNewEpoch unit correct tests"
	@forge test --match-path test/unit/estimator/correct/unitTestCorrect_Estimator_notifyNewEpoch.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEstimatorMakeEstimation:
	@echo "Running estimator makeEstimation unit correct tests"
	@forge test --match-path test/unit/estimator/correct/unitTestCorrect_Estimator_makeEstimation.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectEstimatorAdminFunctions:
	@echo "Running estimator admin functions unit correct tests"
	@forge test --match-path test/unit/estimator/correct/unitTestCorrect_Estimator_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress

#### Revert Tests

unitTestRevertEstimator:
	@echo "Running all estimator unit revert tests"
	@forge test --match-contract unitTestRevert_Estimator --summary --detailed --gas-report -vvv --show-progress


## MateNameService

### Unit tests

#### Correct Tests

unitTestCorrectMateNameService:
	@echo "Running all MateNameService unit correct tests"
	@forge test --match-contract unitTestCorrect_MateNameService --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServicePreRegistrationUsername_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_preRegistrationUsername_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServicePreRegistrationUsername_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_preRegistrationUsername_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceRegistrationUsername_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_registrationUsername_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceRegistrationUsername_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_registrationUsername_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceMakeOffer_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_makeOffer_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceMakeOffer_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_makeOffer_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceWithdrawOffer_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_withdrawOffer_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceWithdrawOffer_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_withdrawOffer_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceAcceptOffer_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_acceptOffer_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceAcceptOffer_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_acceptOffer_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceRenewUsername_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_renewUsername_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceRenewUsername_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_renewUsername_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceAddCustomMetadata_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_addCustomMetadata_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceAddCustomMetadata_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_addCustomMetadata_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceRemoveCustomMetadata_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_removeCustomMetadata_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceRemoveCustomMetadata_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_removeCustomMetadata_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceFlushCustomMetadata_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_flushCustomMetadata_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceFlushCustomMetadata_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_flushCustomMetadata_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceFlushUsername_AsyncExecutionOnPay:
	@echo "Running MateNameService (async execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_flushUsername_AsyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceFlushUsername_SyncExecutionOnPay:
	@echo "Running MateNameService (sync execution on pay) unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_flushUsername_SyncExecutionOnPay.t.sol --summary --detailed --gas-report -vvv --show-progress

unitTestCorrectMateNameServiceAdminFunctions:
	@echo "Running MateNameService unit correct tests"
	@forge test --match-path test/unit/mateNameService/correct/unitTestCorrect_MateNameService_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress

#### Revert tests

unitTestRevertMateNameService:
	@echo "Running MateNameService unit revert tests"
	@forge test --match-contract unitTestRevert_MateNameService --summary --detailed --gas-report -vvv --show-progress

unitTestRevertMateNameServicePreRegistrationUsername:
	@echo "Running MateNameService unit revert tests"
		@forge test --match-path test/unit/mateNameService/revert/unitTestRevert_MateNameService_preRegistrationUsername.t.sol --summary --detailed --gas-report -vvv --show-progress

######################################################################################################




# Fuzz test commands
fuzzTestEvvmPayMultiple:
	@echo "Running EVVM fuzz tests for payMultiple"
	@forge test --match-path test/fuzz/evvm/testEVVMFuzz_payMultiple.t.sol --summary --detailed --gas-report -vvv --show-progress 

fuzzTestEvvmDispersePay:
	@echo "Running EVVM fuzz tests for dispersePay"
	@forge test --match-path test/fuzz/evvm/testEVVMFuzz_dispersePay.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestEvvmPay:
	@echo "Running EVVM fuzz tests for pay"
	@forge test --match-path test/fuzz/evvm/testEVVMFuzz_pay.t.sol --summary --detailed --gas-report -vvv --show-progress 

fuzzTestEvvmCaPay:
	@echo "Running EVVM fuzz tests for caPay"
	@forge test --match-path test/fuzz/evvm/testEVVMFuzz_caPay.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestEvvmDisperseCaPay:
	@echo "Running EVVM fuzz tests for disperseCaPay"
	@forge test --match-path test/fuzz/evvm/testEVVMFuzz_disperseCaPay.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestEvvmAdminFunctions:
	@echo "Running EVVM fuzz tests for admin functions"
	@forge test --match-path test/fuzz/evvm/testEVVMFuzz_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestEvvmProxy:
	@echo "Running EVVM fuzz tests for proxy"
	@forge test --match-path test/fuzz/evvm/testEVVMFuzz_proxy.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsOffers:
	@echo "Running MNS fuzz tests for offers"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_offers.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsPreAndRegistrationUsername:
	@echo "Running MNS fuzz tests for pre-registration and registration of usernames"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_preAndRegistrationUsername.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsRenewUsername:
	@echo "Running MNS fuzz tests for renewing usernames"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_renewUsername.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsAddCustomMetadata:
	@echo "Running MNS fuzz tests for adding custom metadata"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_addCustomMetadata.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsRemoveCustomMetadata:
	@echo "Running MNS fuzz tests for removing custom metadata"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_removeCustomMetadata.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsFlushCustomMetadata:
	@echo "Running MNS fuzz tests for flushing custom metadata"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_flushCustomMetadata.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsFlushUsername:
	@echo "Running MNS fuzz tests for flushing usernames"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_flushUsername.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestMnsAdminFunctions:
	@echo "Running MNS fuzz tests for admin functions"
	@forge test --match-path test/fuzz/mns/testMateNameServiceFuzz_adminFunctions.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestSMateGoldenStaking:
	@echo "Running sMate fuzz tests for golden staking function"
	@forge test --match-path test/fuzz/sMate/testSMateFuzz_goldenStaking.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestSMatePresaleStake:
	@echo "Running sMate fuzz tests for presale stake function"
	@forge test --match-path test/fuzz/sMate/testSMateFuzz_presaleStake.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestSMateExternalStaking:
	@echo "Running sMate fuzz tests for external staking function"
	@forge test --match-path test/fuzz/sMate/testSMateFuzz_externalStaking.t.sol --summary --detailed --gas-report -vvv --show-progress

fuzzTestEstimator:
	@echo "Running estimator fuzz tests"
	@forge test --match-path test/fuzz/sMate/testEstimatorFuzz.t.sol --summary --detailed --gas-report -vvv --show-progress

# Other commands
staticAnalysis:
	@echo "Running static analysis"
	@wake detect all >> reportWake.txt

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
	@echo "-----------------------=Test commands=----------------------"
	@echo ""
	@echo "  make fullTestEvvm ------- Run all EVVM tests"
	@echo "  make testEvvm ----------- Run EVVM unit tests"
	@echo "  make testEvvmRevert ----- Run EVVM revert tests"
	@echo "  make fullTestMNS -------- Run all MNS tests"
	@echo "  make testMNS ------------ Run MNS unit tests"
	@echo "  make testMNSRevert ------ Run MNS revert tests"
	@echo "  make fullTestSMate ------ Run all sMate tests"
	@echo "  make testSMate ---------- Run sMate unit tests"
	@echo "  make testSMateRevert ---- Run sMate revert tests"
	@echo "  make testEstimator ------ Run estimator tests"
	@echo "  make fullProtocolTest --- Run all protocol tests"
	@echo ""
	@echo "-----------------------=Fuzz test commands=----------------------"
	@echo ""
	@echo "  EVVM Fuzz tests"
	@echo ""
	@echo "  make fuzzTestEvvmPayMultiple ---- Run EVVM fuzz tests for payMultiple"
	@echo "  make fuzzTestEvvmDispersePay ---- Run EVVM fuzz tests for dispersePay"
	@echo "  make fuzzTestEvvmPay ------------ Run EVVM fuzz tests for pay"
	@echo "  make fuzzTestEvvmCaPay ---------- Run EVVM fuzz tests for caPay"
	@echo "  make fuzzTestEvvmDisperseCaPay -- Run EVVM fuzz tests for disperseCaPay"
	@echo "  make fuzzTestEvvmAdminFunctions - Run EVVM fuzz tests for admin functions"
	@echo "  make fuzzTestEvvmProxy ---------- Run EVVM fuzz tests for proxy implementations"
	@echo ""
	@echo "  MNS Fuzz tests"
	@echo ""
	@echo "  make fuzzTestMnsOffers --------------------- Run MNS fuzz tests for offers"
	@echo "  make fuzzTestMnsPreAndRegistrationUsername - Run MNS fuzz tests for username registration"
	@echo "  make fuzzTestMnsRenewUsername -------------- Run MNS fuzz tests for renewing usernames"
	@echo "  make fuzzTestMnsAddCustomMetadata ---------- Run MNS fuzz tests for adding custom metadata"
	@echo "  make fuzzTestMnsRemoveCustomMetadata ------- Run MNS fuzz tests for removing custom metadata"
	@echo "  make fuzzTestMnsFlushCustomMetadata -------- Run MNS fuzz tests for flushing custom metadata"
	@echo "  make fuzzTestMnsFlushUsername -------------- Run MNS fuzz tests for flushing usernames"
	@echo "  make fuzzTestMnsAdminFunctions ------------- Run MNS fuzz tests for admin functions"
	@echo ""
	@echo "-----------------------=Other commands=----------------------"
	@echo ""
	@echo "  make staticAnalysis --- Run static analysis and generate report"
	@echo ""
	@echo "---------------------------------------------------------------------------------"