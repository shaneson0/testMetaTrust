// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IDexRouter {
    function xBridge() external pure returns (address);
    function setXBridge(address newXBridge) external;
    function owner() external view returns (address);
    function setPriorityAddress(address newXBridge, bool flag) external;
}
