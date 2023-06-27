// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "src/interfaces/IApproveProxy.sol";
import "lib/forge-std/src/console.sol";

contract Commission {
    address private admin;
    address private immutable APPROVE_PROXY;
    address private immutable NATIVE_TOKEN;
    address private immutable DEX_ROUTER;
    address private payer;
    address private receiver;

    mapping(bytes4 => bool) public accessSelectorId; 

    struct SwapRequest {
        address fromToken;
        uint256 amount;             // amount of swapped fromToken
        uint256 commitssonAmount;   // commitsson fee from fromToken, max commitssonAmount
        address to;
        bytes dexData;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(
        address native_token, 
        address dex_router,
        address approve_proxy
    ) {
        NATIVE_TOKEN = native_token;
        DEX_ROUTER = dex_router;
        APPROVE_PROXY = approve_proxy;
        admin = msg.sender;
    }

    //-------------------------------
    //------- Admin functions -------
    //-------------------------------

    function setProtocolAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    function setAccessSelectorId(bytes4[] memory selectorIds, bool[] memory values) external onlyAdmin{
        require(selectorIds.length == values.length, "length not legal");
        for (uint256 i = 0; i < selectorIds.length; i++) {
            accessSelectorId[selectorIds[i]] = values[i];
        }
    }


    //-------------------------------
    //------- public functions -------
    //-------------------------------
    function swapWithCommisson(
        SwapRequest memory _request
    ) public payable returns (bool success, bytes memory result)
    {
        require(accessSelectorId[bytes4(_request.dexData)], "error selector id");
        if (_request.fromToken == NATIVE_TOKEN) {
            (success, result) = DEX_ROUTER.call{value : _request.amount}(_request.dexData);
            if (success) payable(_request.to).transfer(_request.commitssonAmount);     // fix
        } else {
            payer = msg.sender;
            receiver = _request.to;
            (success, result) = DEX_ROUTER.call(_request.dexData);
            if (success)  IApproveProxy(APPROVE_PROXY).claimTokens(_request.fromToken, msg.sender, _request.to, _request.commitssonAmount);
        }
    }

    function payerReceiver() external view returns(address, address) {
        return (payer, receiver);
    }
    
    receive() external payable {}
}
