#!/bin/bash

# This one is but a simple script to automate certain runs, just to save some time

NETWORK=emulator

# Deploy a contract
CONTRACT_PATH=Chapter5.0/Day1/contracts/RicardoCoinSuperAdmin.cdc
CONTRACT_NAME=RicardoCoinSuperAdmin
SIGNER=emulator-account

# deploy_contract="flow accounts add-contract $CONTRACT_NAME $CONTRACT_PATH --signer $SIGNER --network $NETWORK"
# The Update version of the last command
deploy_contract="flow accounts update-contract $CONTRACT_PATH --signer $SIGNER --network $NETWORK"

# Run transaction 0
TRANSACTION0_PATH=Chapter5.0/Day1/transactions/0_destroySuperVault.cdc
TRANSACTION0_ARGS=""
TRANSACTION0_SIGNER=account03

run_transaction0="flow transactions send $TRANSACTION0_PATH $TRANSACTION0_ARGS --signer $TRANSACTION0_SIGNER --network $NETWORK"

# Run transaction 1
TRANSACTION1_PATH=Chapter5.0/Day1/transactions/4_setupSuperVault.cdc
TRANSACTION1_ARGS=""
TRANSACTION1_SIGNER=account03

run_transaction1="flow transactions send $TRANSACTION1_PATH $TRANSACTION1_ARGS --signer $TRANSACTION1_SIGNER --network $NETWORK"

# Run transaction 2
TRANSACTION2_PATH=Chapter5.0/Day1/transactions/2_mintSuperTokens.cdc
TRANSACTION2_ARGS="0x120e725050340cab 312.50"
TRANSACTION2_SIGNER=emulator-account

run_transaction2="flow transactions send $TRANSACTION2_PATH $TRANSACTION2_ARGS --signer $TRANSACTION2_SIGNER --network $NETWORK"

# Run script 0
SCRIPT0_PATH=Chapter5.0/Day1/scripts/4_profileVaults.cdc
SCRIPT0_ARGS="[0xf8d6e0586b0a20c7,0x120e725050340cab]"

run_script0="flow scripts execute $SCRIPT0_PATH $SCRIPT0_ARGS --network $NETWORK"

# Run transaction 3
TRANSACTION3_PATH=Chapter5.0/Day1/transactions/6_transferTokens.cdc
TRANSACTION3_ARGS="0x120e725050340cab 55.8"
TRANSACTION3_SIGNER=emulator-account

run_transaction3="flow transactions send $TRANSACTION3_PATH $TRANSACTION3_ARGS --signer $TRANSACTION3_SIGNER --network $NETWORK"

# Run script 1

SCRIPT1_PATH=Chapter5.0/Day1/scripts/4_profileVaults.cdc
SCRIPT1_ARGS="[0xf8d6e0586b0a20c7,0x120e725050340cab]"

run_script1="flow scripts execute $SCRIPT1_PATH $SCRIPT1_ARGS --network $NETWORK"

# Run script
# SCRIPT1_PATH=Chapter2.0/Day2/scripts/GetAllTestNFTsInCollection.cdc
# SCRIPT1_ARGS="0xe03daebed8ca0615"

# run_script1="flow scripts execute $SCRIPT1_PATH $SCRIPT1_ARGS --network $NETWORK"

# Run stuff here:
echo "Running ${deploy_contract}"
eval $deploy_contract

echo "Running ${run_transaction0}"
eval $run_transaction0

echo "Running ${run_transaction1}"
eval $run_transaction1

echo "Running ${run_transaction2}"
eval $run_transaction2

echo "Running ${run_script0}"
eval $run_script0

echo "Running ${run_transaction3}"
eval $run_transaction3

echo "Running ${run_script1}"
eval $run_script1

# echo "Running ${run_script1}"
# eval $run_script1
 