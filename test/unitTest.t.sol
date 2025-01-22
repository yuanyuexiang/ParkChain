// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test, console } from "forge-std/Test.sol";
import { Deployment } from "../script/Deployment.s.sol";
import { ParkLotToken } from "../src/ParkLotToken.sol";
import { Issuer } from "../src/Issuer.sol";
import { MockFunctionRouters } from "../src/mocks/MockFunctionRouters.sol";

contract unitTest is Test {
    ParkLotToken public parkLotToken;
    Issuer public issuer;
    Deployment public deployment;
    MockFunctionRouters public mockFunctionRouters;
    address public user;
    uint256 public privateKey;
    uint256 public amount = 1; ///发行数量 1
    uint64 public subscriptionId = 4211; ///订阅id
    uint32 public gasLimit = 30000;
    string[] public args = ["1"]; ///url参数id
    string public response = "ipfs://Qmd2xCfQHecFBg1LDNtoEM3EgyCvCRmUj5d2mVbECPbRkB";
    bytes32 public donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;

    function setUp() public {
        (user, privateKey) = makeAddrAndKey("user");
        deployment = new Deployment();
        (mockFunctionRouters, parkLotToken, issuer) = deployment.run(user);
    }

    function test_issue_onlyOwner() public {
        vm.prank(user);
        vm.expectRevert();
        issuer.issue(user, args, amount, subscriptionId, gasLimit, donID);
    }

    function test_issue_fulfill() public {
        vm.prank(user);
        bytes32 requestId = issuer.issue(user, args, amount, subscriptionId, gasLimit, donID);
        mockFunctionRouters.handleOracleFulfillment(address(issuer), requestId, abi.encodePacked(response), hex"");
        assertEq(parkLotToken.uri(0), response);
    }
}
