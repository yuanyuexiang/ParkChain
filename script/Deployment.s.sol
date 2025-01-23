// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { Script, console } from "forge-std/Script.sol";
import { ParkLotToken } from "../src/ParkLotToken.sol";
import { Issuer } from "../src/Issuer.sol"; // Ensure the path and contract name are correct
import { MockFunctionRouters } from "../src/mocks/MockFunctionRouters.sol";
import { NetWorkConfig } from "./NetWorkConfig.s.sol";

contract Deployment is NetWorkConfig {
    string public sourceCode = vm.readFile("src_function/sourceCode.js");
    Issuer public issuer;
    ParkLotToken public parkLotToken;
    NetWorkParams public networkParams;

    function run(address deployer) public returns (MockFunctionRouters, ParkLotToken, Issuer) {
        networkParams = NetWorkMapping[block.chainid];

        vm.startBroadcast(deployer);
        parkLotToken = new ParkLotToken("");
        issuer = new Issuer(address(parkLotToken), networkParams.functionRouter, sourceCode);
        parkLotToken.setIssuer(address(issuer));
        vm.stopBroadcast();

        console.log("current Chain ID: ", block.chainid);
        console.log("MockFunctionRouters address: ", address(mockFunctionRouters));
        console.log("ParkLotToken address: ", address(parkLotToken));
        console.log("Issuer address: ", address(issuer));

        return (mockFunctionRouters, parkLotToken, issuer);
    }
}
