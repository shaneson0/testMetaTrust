// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "lib/forge-std/src/Test.sol";
import {Commission} from "src/Commission.sol";
import {IApproveProxy} from "src/interfaces/IApproveProxy.sol";
import {IDexRouter} from "src/interfaces/IDexRouter.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/forge-std/src/console.sol";

contract CommissionTest is Test {
    address native_token;
    address dex_router;
    address token_approve_proxy;
    address token_approve;
    address shaneson;
    Commission commisson;
    IApproveProxy approve_proxy;


    bytes4[] selectorIds;
    bool[] values;

    function setUp() public {
        shaneson = 0x790ac11183ddE23163b307E3F7440F2460526957;
        native_token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        dex_router = 0x3b3ae790Df4F312e745D270119c6052904FB6790;
        token_approve_proxy = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
        token_approve = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
        commisson = new Commission(native_token, dex_router, token_approve_proxy);

        selectorIds.push(bytes4(0x0d5f0e3b));
        selectorIds.push(bytes4(0x9871efa4));
        selectorIds.push(bytes4(0xd8837daf));
        values.push(true);
        values.push(true);
        values.push(true);

        // set selectId
        commisson.setAccessSelectorId(selectorIds, values);
    }

    // https://etherscan.io/tx/0xa2785434c9aa678fa775e53ae929f62266a4a824d916fce293abf3e1f809a70d
    function testSwapWithCommissonOnNativeToken() public {

        uint256 before_shaneson_balance = address(shaneson).balance;
        uint256 before_owner_balance = address(this).balance;
        uint256 fromTokenAmount = 0.4 * 1e18;
        uint256 commissonAmount = 0.04 * 1e18;
        
        address fromToken = native_token;
        bytes memory dexData = hex"9871efa40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000058d15e176280000000000000000000000000000000000000000000000000000000000e2a1dc164f0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340f9bed17dea46546d56e8bc4a5a1e2e0b8628e947";

        Commission.SwapRequest memory swapRequest = Commission.SwapRequest (
            fromToken,
            fromTokenAmount,
            commissonAmount,
            shaneson,
            dexData
        );
 
        commisson.swapWithCommisson{value: 0.44 ether}(swapRequest);

        // check balance
        uint256 after_shaneson_balance = address(shaneson).balance;
        uint256 after_owner_balance = address(this).balance;

        assert(after_shaneson_balance == before_shaneson_balance + commissonAmount);
        assert(after_owner_balance == before_owner_balance - fromTokenAmount - commissonAmount);
    }

    function testSwapWithCommissonERC20Token() public {
        address fromToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;     // WETH
        address owner = 0x44Cc771fBE10DeA3836f37918cF89368589b6316;          // whale
        uint256 fromTokenAmount = 11281313306333120;
        uint256 commissonAmount = 308439399189993;

        uint256 before_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(owner);


        // addProxy & setPriorityAddress
        vm.startPrank(0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87);

        IApproveProxy(token_approve_proxy).addProxy(address(commisson));
        IDexRouter(dex_router).setPriorityAddress( address(commisson), true );

        vm.stopPrank();

        // swap
        vm.startPrank(owner);

        // 790ac11183ddE23163b307E3F7440F2460526957
        bytes memory dexData = hex"d8837daf0000000000284d4b42ca0c0144Cc771fBE10DeA3836f37918cF89368589b63160000000000000000000000000000000000000000000000000028144b70394fc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000100000000000000000000000011b815efb8f581194ae79006d24e0d814b7697f6";
        IERC20(fromToken).approve(token_approve, 0xffffffffffffffffffff);

        Commission.SwapRequest memory swapRequest = Commission.SwapRequest (
            fromToken,
            fromTokenAmount,
            commissonAmount,
            shaneson,
            dexData
        );
        commisson.swapWithCommisson(swapRequest);
        vm.stopPrank();

        // check balance
        uint256 after_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(owner);

        assert(after_shaneson_balance == before_shaneson_balance + commissonAmount);
        assert(after_owner_balance == before_owner_balance - fromTokenAmount - commissonAmount);
    }

}






















