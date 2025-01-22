// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import { Script, console } from "forge-std/Script.sol";
import { ParkLotToken } from "../src/ParkLotToken.sol";
import { Issuer } from "../src/Issuer.sol";
import { MockFunctionRouters } from "../src/mocks/MockFunctionRouters.sol";

contract Deployment is Script {
    MockFunctionRouters public mockFunctionRouters;
    ParkLotToken public parkLotToken;
    Issuer public issuer;
    string public sourceCode = vm.readFile("src_function/sourceCode.js");

    function run(address deployer) public returns (MockFunctionRouters, ParkLotToken, Issuer) {
        vm.startBroadcast(deployer);
        mockFunctionRouters = new MockFunctionRouters();
        parkLotToken = new ParkLotToken("");
        issuer = new Issuer(address(parkLotToken), address(mockFunctionRouters), sourceCode);
        parkLotToken.setIssuer(address(issuer));
        vm.stopBroadcast();
        console.log("MockFunctionRouters address: ", address(mockFunctionRouters));
        console.log("ParkLotToken address: ", address(parkLotToken));
        console.log("Issuer address: ", address(issuer));

        return (mockFunctionRouters, parkLotToken, issuer);
    }
}
