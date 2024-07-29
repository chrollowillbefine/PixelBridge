Smart Contract Documentation: BridgePixel
Summary

BridgePixelToken is a Solidity smart contract deployed on Flare or Sonbird blockchains. 
It transfer tokens on this way:
    - from Flare transfer Flr tokens, release pixelBridgeFlr tokens on Songbird chain.
    - from Flare transfer pixelBridgeSGB tokens, release SGB tokens on Songbird chain.
    - from Songbird transfer SGB tokens, release pixelBridgeSGB tokens on Flare chain.
    - from Songbird transfer pixelBridgeFlr tokens, release Flr tokens on Flare chain.

Contract Details

    Solidity Version: ^0.8.20
    Contract Name: BridgePixel

Dependencies

The contract depends on the following OpenZeppelin contracts:
    Ownable.sol
    ERC20.sol
    IERC20.sol
    ReentrancyGuard.sol
    SafeERC20.sol


How to use:

Admin part:
-deploy contract
-initialize all function wich starts with "Set"
-sometimes collect fees

User part:
1) Deposit token for bridge transfer:
    - if you deposit Flr or SGB tokens you should use depositNativeTokenForBridgeTransfer
    - if you deposit pixelBridgeFlr or pixelBridgeSGB tokens you should use depositPixelTokenForBridgeTransfer() 
    Note: Check that fee is included in this deposit.

    Also save transaction hash, timestamp and block number. And save value to deposit and total value included fee on this transaction.

    Funtion depositNativeTokenForBridgeTransfer()  has variables:
    - _amount: how much you want to transfer.
    - msg.value of transaction should be _amount +  fee

    Funtion depositPixelTokenForBridgeTransfer() has variables:
    - _amount: how much you want to transfer.
    - before calling this funcion approve pixel tokens for transfer for bridge:
        the amount shoud include fee.
    
2) Wait till transaction is mined.
3) On other chain call function requestWithdraw() 
    State connector emmits "_submissionRoundID", save it.

    Funtion requestWithdraw()  has variables:
    -isNative: 
        isNative is true when from other chain(native token) tom this chain pixelToken
        isNative is false when from other chain(pixel token) tom this chain native token
    -_txHash: hash of transaction: block number of transaction you did on other bridge
    -_blockNumber: block number of transaction you did on other bridge
    -_timestamp: timestamp of transaction you did on other bridge
    -_valueTotal: msg.value of transaction you did on other bridge
    -_valueToWithdraw: _amount of transaction you did on other bridge 

4) Check if submition round is ready by calling function checkIfRoundAttestationReady()
    if ready, go to next step, if not, wait longer and call this function again
    Function checkIfRoundAttestationReady() has variable:
    -_submissionRoundID: emmited on State connector after you call function requestWithdraw().

5) Call function withdrawFromBridge()
    Function withdrawFromBridge() has variable:
    isNative: 
        isNative is true when from other chain(native token) tom this chain pixelToken
        isNative is false when from other chain(pixel token) tom this chain native token
    _proof: list to create merkle proof
    you can get it by  request via POST /api/proof/get-specific-proof 
    https://evm-verifier.flare.network/
    Given {roundId: number, requestBytes: string}
    The response data contains:
        roundId:	ID of the attestation round in which the request was considered.
        hash:	Hash of the attestation as in the Merkle tree.
        requestBytes:	Encoded attestation request.
        response:	Response to the request as specified by the attestation type.
        merkleProof: Array of hashes that prove that the request's hash is included in the Merkle tree. It can be an empty array if only one request is confirmed in the round.
            

    _index: index where hash of our transaction is loctated in this list
    _submissionRoundID: emmited on State connector after you call function requestWithdraw()
    _txHash: hash of transaction: block number of transaction you did on other bridge
    _blockNumber: block number of transaction you did on other bridge
    _timestamp: timestamp of transaction you did on other bridge
    _valueTotal: msg.value of transaction you did on other bridge
    _valueToWithdraw: _amount of transaction you did on other bridge 

