#!/bin/bash

# This one is but a simple script to automate certain runs, just to save some time

NETWORK=emulator

# Deploy a contract
CONTRACT_PATH=Chapter1.0/Day1/contracts/Record.cdc
CONTRACT_NAME=Record
SIGNER=emulator-account

# deploy_contract="flow accounts add-contract $CONTRACT_NAME $CONTRACT_PATH --signer $SIGNER --network $NETWORK"
# The Update version of the last command
deploy_contract="flow accounts update-contract $CONTRACT_PATH --signer $SIGNER --network $NETWORK"

# Run transaction 1
TRANSACTION1_PATH=Chapter1.0/Day1/transactions/createCollection.cdc
TRANSACTION1_ARGS=""
TRANSACTION1_SIGNER=account01

run_transaction1="flow transactions send $TRANSACTION1_PATH $TRANSACTION1_ARGS --signer $TRANSACTION1_SIGNER --network $NETWORK"

# Run transaction 2
TRANSACTION2_PATH=Chapter1.0/Day1/transactions/mintNFTs.cdc
TRANSACTION2_ARGS="0xe03daebed8ca0615"
TRANSACTION2_SIGNER="emulator-account"

run_transaction2="flow transactions send $TRANSACTION2_PATH $TRANSACTION2_ARGS --signer $TRANSACTION2_SIGNER --network $NETWORK"

# Run script
SCRIPT1_PATH=Chapter1.0/Day1/scripts/getAllRecords.cdc
SCRIPT1_ARGS="0xe03daebed8ca0615"

run_script1="flow scripts execute $SCRIPT1_PATH $SCRIPT1_ARGS --network $NETWORK"

# Run stuff here:
echo "Running ${deploy_contract}"
eval $deploy_contract

echo "Running ${run_transaction1}"
eval $run_transaction1

echo "Running ${run_transaction2}"
eval $run_transaction2

echo "Running ${run_script1}"
eval $run_script1