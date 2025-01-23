// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { Script, console } from "forge-std/Script.sol";
import { ParkLotToken } from "../src/ParkLotToken.sol";
import { Issuer } from "../src/Issuer.sol";
import { MockFunctionRouters } from "../src/mocks/MockFunctionRouters.sol";

contract NetWorkConfig is Script {
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant ARBITRUM_SEPOLIA_CHAIN_ID = 421614;
    MockFunctionRouters mockFunctionRouters;

    struct NetWorkParams {
        uint64 subscriptionId;
        uint32 gasLimit;
        bytes32 donID;
        address functionRouter;
    }
    mapping(uint256 => NetWorkParams) public NetWorkMapping;

    constructor() {
        NetWorkMapping[ETH_SEPOLIA_CHAIN_ID] = getSepoliaNetwork();
        NetWorkMapping[LOCAL_CHAIN_ID] = getLocalNetwork();
        NetWorkMapping[ARBITRUM_SEPOLIA_CHAIN_ID] = getArbitrumSepoliaNetwork();
    }

    function getSepoliaNetwork() public pure returns (NetWorkParams memory) {
        return
            NetWorkParams({
                subscriptionId: 4211,
                gasLimit: 30000,
                donID: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000,
                functionRouter: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0
            });
    }

    function getLocalNetwork() public returns (NetWorkParams memory) {
        vm.startBroadcast();
        mockFunctionRouters = new MockFunctionRouters();
        vm.stopBroadcast();
        return
            NetWorkParams({
                subscriptionId: 1,
                gasLimit: 30000,
                donID: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000,
                functionRouter: address(mockFunctionRouters)
            });
    }

    function getArbitrumSepoliaNetwork() public pure returns (NetWorkParams memory) {
        return
            NetWorkParams({
                subscriptionId: 4211, //TODO: change this
                gasLimit: 30000,
                donID: 0x66756e2d617262697472756d2d7365706f6c69612d3100000000000000000000,
                functionRouter: 0x234a5fb5Bd614a7AA2FfAB244D603abFA0Ac5C5C
            });
    }
}
