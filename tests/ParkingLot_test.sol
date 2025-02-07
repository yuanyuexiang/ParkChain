// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "remix_tests.sol";
import "remix_accounts.sol";
import "../contracts/ParkingLot.sol";

contract ParkingLotTest {

    ParkingLot s;

    function beforeAll () public {
        address acc0 = TestsAccounts.getAccount(0);
        // acc0 will be set as initial owner
        s = new ParkingLot(acc0);
    }

    function testTokenNameAndSymbol () public {
        Assert.equal(s.name(), "ParkingLot", "token name did not match");
        Assert.equal(s.symbol(), "MTK", "token symbol did not match");
    }
}