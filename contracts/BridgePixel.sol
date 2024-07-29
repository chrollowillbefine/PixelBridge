// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @dev Interface of the StateConnector, the part which is used in Brigge
 * 
*/
interface iStateConnector {
    function requestAttestations(
        bytes calldata _data
    ) external;

    function lastFinalizedRoundId(
    ) external view returns (uint256);

    function getAttestation(
        uint256 _bufferNumber
    ) external view returns (bytes32);

    function merkleRoot(
        uint256 _roundId
    ) external view returns (bytes32); 
}

/**
 * @dev Interface of the StateConnector, the part which is used in Brigge
 * 
*/
interface iBridgePixelToken {
    function mint(
        address account, 
        uint256 value
    ) external;

    function burn(
        address from,
        uint256 value
    ) external;
}


// contract BridgePixel is Ownable, ReentrancyGuard {
contract BridgePixel is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // Name of Bridge
    string public name;

    // Address of Bridge Pixel token
    address public pixelBridgeTokenAddress;
    iBridgePixelToken public pixelBridgeToken;

    // Address of Bridge contract of opposite Chain(if this chain in Songbird, than opposite is Flare and vise versa)
    address public oppositePixelBridgeContract;

    // Attestation type: EVMTransaction
    bytes32 public attestationTypeEVM;

    // Name of opposite chain upper case in bytes32
    bytes32 public oppositeSourseID; 

    // Number of block confirmation required on opposite chain transaction.
    uint16 public oppositeRequiredConfirmation;

    // The timestamp of the earliest data (block) needed to assemble the responseBody.
    uint64 public currentLowestUsedTimestamp; // 18446744073709552000

    // Mapping new requests to withdraw 
    mapping(bytes32 => bool) public openCheckHashForSecuityFromCollision;

    // Mapping old requests to withdraw 
    mapping(bytes32 => bool) public closedCheckHashForSecuityFromCollision;
    
    /**
     * @dev Initializes the contract by setting a `name`.
     */
    constructor(string memory _name) Ownable(msg.sender) {
        name = _name;   
    }

    // Address of state connector contract
    address public stateConnector;

    // Fee of protocol
    uint256 public fee;

    // Denominator of fee
    uint256 constant denom = 10000;

    // Quantity of native token(Flr or SGB), without any fee, donations, etc.
    uint256 public totalBalanceNative;


    // Struct of request body for state connector
    struct RequestBody {
        bytes32 transactionHash;
        uint16 requiredConfirmations;
        bool provideInput; // "If true, \"input\" field is included in the response."
        bool listEvents; // "If true, events indicated by `logIndices` are included in the response. Otherwise, no events are included in the response."
        uint32[] logIndices; // "If `listEvents` is `false`, this should be an empty list, otherwise, the request is rejected. 
                            // If `listEvents` is `true`, this is the list of indices (logIndex) of the events to be relayed (sorted by the requestor). The array should contain at most 50 indices. 
                            // If empty, it indicates all events in order capped by 50."
    }

    // Struct of request for state connector
    struct Request {
        bytes32 attestationType;
        bytes32 sourceId; // ID of the data source
        bytes32 messageIntegrityCode; // MessageIntegrityCode` that is derived from the expected response.
        RequestBody requestBody;
    }

    // Struct of event for state connector
    struct Event {
        uint32 logIndex; // The consecutive number of the event in block.
        address emitterAddress; // The address of the contract that emitted the event.
        bytes32[] topics; // An array of up to four 32-byte strings of indexed log arguments.
        bytes data; // Concatenated 32-byte strings of non-indexed log arguments. At least 32 bytes long.
        bool removed;
    }

    // Struct of response body for state connector
    struct ResponseBody{
        uint256 blockNumber; // Number of the block in which the transaction is included.
        uint256 timestamp; // Timestamp of the block in which the transaction is included.
        address sourceAddress; // The address (from) that signed the transaction.
        bool isDeployment; // Indicate whether it is a contract creation transaction.
        address receivingAddress; // The address (to) of the receiver of the initial transaction. Zero address if isDeployment is true.
        uint256 value; // The value transferred by the initial transaction in wei.
        bytes input; // if provideInput, this is the data send along with the initial transaction. Otherwise it is the default value 0x00.
        uint8 status; // Status of the transaction 1 - success, 0 - failure.
        Event[] events; // If listEvents is true, an array of the requested events. Sorted by the logIndex in the same order as logIndices. Otherwise, an empty array.
    }

    // Struct of response  for state connector
    struct Response {
        bytes32 attestationType; 
        bytes32 sourceId;
        uint64 votingRound; // The ID of the State Connector round in which the request was considered. This is a security measure to prevent collision of attestation hashes.
        uint64 lowestUsedTimestamp; // The timestamp of the earliest data (block) needed to assemble the responseBody.
        RequestBody requestBody;
        ResponseBody responseBody;
    }

    // Event, whic is emitted after depositin tokens.
    event NativeBridgeTrasnfer(address indexed _initiator, uint256 _value);

    **
     * @dev Set `pixelBridgeToken`.
     *
     */
    function SetPixelBridgeToken(address _pixelBridgeToken) external onlyOwner(){
        pixelBridgeTokenAddress = _pixelBridgeToken;
        pixelBridgeToken = iBridgePixelToken(_pixelBridgeToken);
    }

    **
     * @dev Set `fee`.
     *
     */
    function SetFeeBridge(uint256 _price) external onlyOwner(){
        fee = _price;
    }

    **
     * @dev Set `attestationTypeEVM`.
     *
     */
    function SetAttestationTypeEVM(bytes32 _attestationType) external onlyOwner(){
        // 0x45564d5472616e73616374696f6e000000000000000000000000000000000000
        // EVMTransaction
        attestationTypeEVM = _attestationType;
    }
    

    **
     * @dev Set `oppositeSourseID`.
     *
     */
    function SetOppositeSourceId(bytes32 _sourceId) external onlyOwner(){
        // FLR
        // 0x464c520000000000000000000000000000000000000000000000000000000000
        // SGB
        // 0x5347420000000000000000000000000000000000000000000000000000000000
        // Coston (Songbird testen) songbirdTestnet CFLR
        // 0x43464c5200000000000000000000000000000000000000000000000000000000
        // Coston2 (Flare testnet) flareTestnet C2FLR
        // 0x5347420000000000000000000000000000000000000000000000000000000000
        oppositeSourseID = _sourceId;
    }

    **
     * @dev Set `oppositeRequiredConfirmation`.
     *
     */
    function SetRequiredConfirmation(uint16 _requiredConfirmation) external onlyOwner(){
        // 11 for FLR
        // 61 for SGB
        oppositeRequiredConfirmation = _requiredConfirmation;
    }

    **
     * @dev Set `oppositePixelBridgeContract`.
     *
     */
    function SetOppositePixelBridgeContract(address _oppositePixelBridgeContract) external onlyOwner(){
        oppositePixelBridgeContract = _oppositePixelBridgeContract;
    }

    **
     * @dev Set `stateConnector` address.
     *
     */
    function SetStateConnectorAddress(address _stateConnector) external onlyOwner(){
        stateConnector = _stateConnector;
    }

    **
     * @dev Set `currentLowestUsedTimestamp`.
     *
     */
    function SetCurrentLowestUsedTimestamp(uint64 _currentLowestUsedTimestamp) external onlyOwner(){
        currentLowestUsedTimestamp = _currentLowestUsedTimestamp;
    }

    **
     * @dev convert uint256 to uint64.
     *
     */
    function convertUint256ToUint64(uint256 _value) public pure returns (uint64) {
        require(_value <= type(uint64).max, "Value exceeds uint64 range");
        return uint64(_value);
    }

    /**
     * @dev deposit native token to this contract for transfer to other chain.
     *
     * Requirements:
     *
     * - (msg.value minus `_amount`)  must be bigger or equal to amount of fee.
     *
     */
    function depositNativeTokenForBridgeTransfer (uint256 _amount) external payable nonReentrant {
        uint256 ifReminder;
        if (fee * _amount % denom == 0){
            ifReminder = 0;
        } else{
            ifReminder = 1;
        }
        uint256 totalFee = fee * _amount / denom + ifReminder;
        require(msg.value - _amount >= totalFee, "not enough fee");
        require(totalFee > 0, "not enough fee");

        totalBalanceNative = totalBalanceNative + _amount;
    }

    /**
     * @dev deposit Pixel bridge token to this contract for transfer to other chain.
     *
     * Requirements:
     *
     * - real number of tokens that you want to transfer should be: _amount - fee * _amount / denom + ifReminder
     *
     * Emits a {NativeBridgeTrasnfer} event.
     */
    function depositPixelTokenForBridgeTransfer (uint256 _amount) external payable nonReentrant {
        uint256 ifReminder;
        if (fee * _amount % denom == 0){
            ifReminder = 0;
        } else{
            ifReminder = 1;
        }
        uint256 totalFee = fee * _amount / denom + ifReminder;
        require(totalFee > 0, "not enough fee");
        
        emit NativeBridgeTrasnfer(msg.sender, _amount - totalFee);

        SafeERC20.safeTransfer(IERC20(pixelBridgeTokenAddress), address(this), _amount - totalFee);
        iBridgePixelToken(pixelBridgeTokenAddress).burn(address(this), _amount - totalFee);

    }

    /**
     * @dev request attestation from state connector, after deposit on other chain.
     *
     * isNative is true when from other chain(native token) tom this chain pixelToken
     * isNative is false when from other chain(pixel token) tom this chain native token
     *
     * Requirements:
     *
     * - you should deposit tokens on other chain
     * - you should wait when transaction is mined
     *
     */
    function requestWithdraw(bool isNative, bytes32 _txHash, uint256 _blockNumber, uint256 _timestamp, uint256 _valueTotal, uint256 _valueToWithdraw) external payable nonReentrant {
        bytes32 hashSec = keccak256(abi.encodePacked(keccak256(abi.encodePacked(isNative)), keccak256(abi.encodePacked(_txHash)), keccak256(abi.encodePacked(_blockNumber)), keccak256(abi.encodePacked(_timestamp)), keccak256(abi.encodePacked(_valueTotal)), keccak256(abi.encodePacked(_valueToWithdraw)), keccak256(abi.encodePacked(msg.sender))));
        require(openCheckHashForSecuityFromCollision[hashSec] == false, "the data is already used");
        openCheckHashForSecuityFromCollision[hashSec] == true;
        require(closedCheckHashForSecuityFromCollision[hashSec] == false, "the data is already used and withdawal happend");

        uint32[] memory indices;
        Event[] memory responseEvents;
        bool _listEventsInclude;

        bytes32[] memory newTopics = new bytes32[](1);
        newTopics[0] = bytes32(uint256(uint160(msg.sender)));

        if (isNative) {
            _listEventsInclude = false;
            indices = new uint32[](0); 
            responseEvents = new Event[](0); 
        } else{
            _listEventsInclude = true;
            indices = new uint32[](1); 
            indices[0] = 0; 

            responseEvents = new Event[](1); 
            
            Event memory nEvent = Event({
                logIndex: 0,
                emitterAddress: oppositePixelBridgeContract, 
                topics: newTopics,
                data: abi.encodePacked(_valueToWithdraw),
                removed: false 
            });
            responseEvents[0] = nEvent;
        }
        
        RequestBody memory newReqBody = RequestBody({
            transactionHash: _txHash,
            requiredConfirmations: oppositeRequiredConfirmation, 
            provideInput: true,
            listEvents: _listEventsInclude,
            logIndices: indices
        });

        ResponseBody memory newRespBody = ResponseBody({
            blockNumber: _blockNumber,
            timestamp: _timestamp,
            sourceAddress: msg.sender,
            isDeployment: false,
            receivingAddress: oppositePixelBridgeContract,
            value: _valueTotal,
            input: abi.encodePacked(_valueToWithdraw),
            status: 1,
            events: responseEvents
        });

        Response memory newResp = Response({
            attestationType:  attestationTypeEVM,
            sourceId: oppositeSourseID,
            votingRound: 0,
            lowestUsedTimestamp: currentLowestUsedTimestamp,
            requestBody: newReqBody,
            responseBody: newRespBody
        });

        // The Message Integrity Code (MIC) is the hash of the expected attestation response with votingRound set to zero together with the string "Flare". 
        // A requester provides the MIC to attestation providers, so they can check the verifier's response against the requester's expectations. Hence, the requestor must know the response in advance.
        bytes32 MIC = keccak256(abi.encode(newResp,"Flare"));
        
        Request memory newReq = Request({
            attestationType: attestationTypeEVM,
            sourceId: oppositeSourseID,
            messageIntegrityCode: MIC, // bytes32
            requestBody: newReqBody
        });

        bytes memory encodedRequest = abi.encode(
            newReq.attestationType,
            newReq.sourceId,
            newReq.requestBody.transactionHash,
            newReq.requestBody.requiredConfirmations,
            newReq.requestBody.provideInput,
            newReq.requestBody.listEvents,
            newReq.requestBody.logIndices
        );
        iStateConnector(stateConnector).requestAttestations(encodedRequest);
    }

    /**
     * @dev check if attestation is ready for  *_submissionRoundID*.
     *
     */
    function checkIfRoundAttestationReady(uint64 _submissionRoundID) external view returns(bool _readyStatus) {
        uint256 lastFinalisedRound = iStateConnector(stateConnector).lastFinalizedRoundId();
        if (lastFinalisedRound < _submissionRoundID) {
            _readyStatus = false;
        } else {
            _readyStatus = true;
        }
    }

    /**
     * @dev verify is proof is really part of merkle root.
     *
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf,
        uint256 index
    ) public pure returns (bool) {
        bytes32 hash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return hash == root;
    }


    /**
     * @dev crate keccack 256 hash of event.
     *
     */
    function hashEvent(Event memory _event) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _event.logIndex,
            _event.emitterAddress,
            _event.topics,
            _event.data,
            _event.removed
        ));
    }

    /**
     * @dev crate keccack 256 hash of multiple events.
     *
     */
    function hashEvents(Event[] memory _events) internal pure returns (bytes32) {
        bytes32[] memory eventsHashes = new bytes32[](_events.length);
        for (uint256 i = 0; i < _events.length; i++) {
            eventsHashes[i] = hashEvent(_events[i]);
        }
        return keccak256(abi.encodePacked(eventsHashes));
    }

    /**
     * @dev crate keccack 256 hash of request body.
     *
     */
    function hashRequestBody(RequestBody memory _requestBody) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _requestBody.transactionHash,
            _requestBody.requiredConfirmations,
            _requestBody.provideInput,
            _requestBody.listEvents,
            _requestBody.logIndices
        ));
    }

    /**
     * @dev crate keccack 256 hash of response body.
     *
     */
    function hashResponseBody(ResponseBody memory _responseBody) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _responseBody.blockNumber,
            _responseBody.timestamp,
            _responseBody.sourceAddress,
            _responseBody.isDeployment,
            _responseBody.receivingAddress,
            _responseBody.value,
            _responseBody.input,
            _responseBody.status,
            hashEvents(_responseBody.events)
        ));
    }

    /**
     * @dev crate keccack 256 hash of request.
     *
     */
    function hashRequest(Request memory _request) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _request.attestationType,
            _request.sourceId,
            _request.messageIntegrityCode,
            hashRequestBody(_request.requestBody)
        ));
    }

    /**
     * @dev crate keccack 256 hash of response.
     *
     */
    function hashResponse(Response memory _response) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _response.attestationType,
            _response.sourceId,
            _response.votingRound,
            _response.lowestUsedTimestamp,
            hashRequestBody(_response.requestBody),
            hashResponseBody(_response.responseBody)
        ));
    }

    /**
     * @dev crate keccack 256 hash of merkle root leaf.
     *
     * Requirements:
     *
     * - this request should be opened and not closed
     *
     */
    function calculateHashSec(bool isNative, bytes32 _txHash, uint256 _blockNumber, uint256 _timestamp, uint256 _valueTotal, uint256 _valueToWithdraw) internal view {
        bytes32 hashSec = keccak256(abi.encodePacked(
            keccak256(abi.encodePacked(isNative)),
            keccak256(abi.encodePacked(_txHash)),
            keccak256(abi.encodePacked(_blockNumber)),
            keccak256(abi.encodePacked(_timestamp)),
            keccak256(abi.encodePacked(_valueTotal)),
            keccak256(abi.encodePacked(_valueToWithdraw)),
            keccak256(abi.encodePacked(msg.sender))
        ));
        require(openCheckHashForSecuityFromCollision[hashSec] == true, "the data is already used");
        openCheckHashForSecuityFromCollision[hashSec] == true;
        require(closedCheckHashForSecuityFromCollision[hashSec] == false, "the data is already used and withdawal happend");
        closedCheckHashForSecuityFromCollision[hashSec] == true;
    }

    /**
     * @dev check if the request is equal to leaf which is provided.
     *
     */
    function checkIfRequestIsEqualToLeaf(bool isNative, bytes32[] memory _proof, uint256 _index, uint256 _submissionRoundID,  bytes32 _txHash, uint256 _blockNumber, uint256 _timestamp, uint256 _valueTotal, uint256 _valueToWithdraw) internal view {
        uint32[] memory indices;
        Event[] memory responseEvents;
        bool _listEventsInclude;

        bytes32[] memory newTopics = new bytes32[](1);
        newTopics[0] = bytes32(uint256(uint160(msg.sender)));

        if (isNative) {
            _listEventsInclude = false;
            indices = new uint32[](0); 
            responseEvents = new Event[](0); 
        } else{
            _listEventsInclude = true;
            indices = new uint32[](1); 
            indices[0] = 0; 

            responseEvents = new Event[](1); 
            Event memory nEvent = Event({
                logIndex: 0,
                emitterAddress: oppositePixelBridgeContract, 
                topics: newTopics,
                data: abi.encodePacked(_valueToWithdraw),
                removed: false 
            });
            responseEvents[0] = nEvent;
        }

        RequestBody memory newReqBody = RequestBody({
            transactionHash: _txHash,
            requiredConfirmations: oppositeRequiredConfirmation, 
            provideInput: true,
            listEvents: _listEventsInclude,
            logIndices: indices
        });

        ResponseBody memory newRespBody = ResponseBody({
            blockNumber: _blockNumber,
            timestamp: _timestamp,
            sourceAddress: msg.sender,
            isDeployment: false,
            receivingAddress: oppositePixelBridgeContract,
            value: _valueTotal,
            input: abi.encodePacked(_valueToWithdraw),
            status: 1,
            events: responseEvents
        });

        Response memory newRespForMerkle = Response({
            attestationType:  attestationTypeEVM,
            sourceId: oppositeSourseID,
            votingRound: convertUint256ToUint64(_submissionRoundID),
            lowestUsedTimestamp: currentLowestUsedTimestamp,
            requestBody: newReqBody,
            responseBody: newRespBody
        });

        require(hashResponse(newRespForMerkle) == _proof[_index], "leaf is not equal to real response");
    }

    /**
     * @dev withdraw from bridge.
     *
     * isNative is true when from other chain(native token) tom this chain pixelToken
     * isNative is false when from other chain(pixel token) tom this chain native token
     *
     * Requirements:
     *
     * - you should deposit tokens on other bridge
     * - you should wait transaction to be mined
     * - you should open request for withdraw
     * - you should provide correct date
     *
     */
    function withdrawFromBridge(bool isNative, bytes32[] memory _proof, uint256 _index, uint256 _submissionRoundID,  bytes32 _txHash, uint256 _blockNumber, uint256 _timestamp, uint256 _valueTotal, uint256 _valueToWithdraw) external payable nonReentrant {
        calculateHashSec(isNative, _txHash, _blockNumber, _timestamp, _valueTotal, _valueToWithdraw);

        bytes32 merkleRoot = iStateConnector(stateConnector).merkleRoot(_submissionRoundID);

        checkIfRequestIsEqualToLeaf(isNative, _proof, _index, _submissionRoundID,  _txHash, _blockNumber, _timestamp, _valueTotal, _valueToWithdraw);

        bool isChecked = verify(_proof, merkleRoot, _proof[_index], _index);
        require(isChecked == true, "transaction is not prooved");
        if(isNative){
            iBridgePixelToken(pixelBridgeTokenAddress).mint(msg.sender, _valueToWithdraw);
        } else {
            (bool sent, ) = msg.sender.call{ value: _valueToWithdraw }("");
            require(sent, "Failed to send Ether");
        }
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev withdraw fees and donation of non native token.
     *
     */
    function withdrawToken(
        address token,
        uint256 amount,
        address to
    ) public onlyOwner {
        SafeERC20.safeTransfer(IERC20(token), to, amount);
    }

    /**
     * @dev withdraw fees and donation of native token.
     *
     */
    function withdrawNative(uint256 msgValue, address to) public payable onlyOwner nonReentrant {
        // add check if donated
        require(msgValue <= address(this).balance - totalBalanceNative);
        (bool sent, ) = to.call{ value: msgValue }("");
        require(sent, "Failed to send Ether");
    }
}