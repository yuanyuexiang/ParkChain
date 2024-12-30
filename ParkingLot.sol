// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ParkingLot is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _spotIdCounter;

    struct ParkingSpot {
        uint256 id;
        address owner;
        bool isAvailable;
        string leaseInfo; // 租赁信息
        uint256 leaseEndTime; // 租赁结束时间
        uint256 rentalFee; // 租赁费用
        address renter; // 当前租赁者
    }

    mapping(uint256 => ParkingSpot) public parkingSpots;

    event SpotCreated(uint256 id, address owner);
    event SpotLeased(uint256 id, string leaseInfo, uint256 rentalFee, uint256 leaseEndTime, address renter);
    event SpotReleased(uint256 id);
    event LeaseTerminated(uint256 id, uint256 refund);

    // 修复构造函数
    constructor() ERC721("ParkingLotNFT", "PLNFT") Ownable(address(msg.sender)) {
        // 默认初始所有者是合约的部署者，OpenZeppelin 自动处理
        
    }

    // 创建车位 NFT
    function createSpot() public {
        _spotIdCounter.increment();
        uint256 newSpotId = _spotIdCounter.current();
        parkingSpots[newSpotId] = ParkingSpot(newSpotId, msg.sender, true, "", 0, 0, address(0));
        _mint(msg.sender, newSpotId);
        emit SpotCreated(newSpotId, msg.sender);
    }

    // 租赁车位
    function leaseSpot(uint256 spotId, string memory leaseInfo, uint256 rentalFee, uint256 duration) public payable {
        require(parkingSpots[spotId].isAvailable, "Spot is not available");
        require(ownerOf(spotId) != msg.sender, "Owner cannot lease their own spot");
        require(msg.value >= rentalFee, "Insufficient rental fee");

        parkingSpots[spotId].isAvailable = false;
        parkingSpots[spotId].leaseInfo = leaseInfo;
        parkingSpots[spotId].rentalFee = rentalFee;
        parkingSpots[spotId].leaseEndTime = block.timestamp + duration;
        parkingSpots[spotId].renter = msg.sender;

        // 退还超额费用
        if (msg.value > rentalFee) {
            payable(msg.sender).transfer(msg.value - rentalFee);
        }

        emit SpotLeased(spotId, leaseInfo, rentalFee, parkingSpots[spotId].leaseEndTime, msg.sender);
    }

    // 释放车位
    function releaseSpot(uint256 spotId) public {
        require(msg.sender == parkingSpots[spotId].owner, "Only owner can release the spot");
        require(!parkingSpots[spotId].isAvailable, "Spot is already available");
        require(block.timestamp >= parkingSpots[spotId].leaseEndTime, "Lease period is not over yet");

        delete parkingSpots[spotId].leaseInfo;
        delete parkingSpots[spotId].rentalFee;
        delete parkingSpots[spotId].leaseEndTime;
        parkingSpots[spotId].isAvailable = true;
        parkingSpots[spotId].renter = address(0);

        emit SpotReleased(spotId);
    }

    // 提前终止租赁
    function terminateLease(uint256 spotId) public {
        require(msg.sender == parkingSpots[spotId].owner, "Only owner can terminate the lease");
        require(!parkingSpots[spotId].isAvailable, "Spot is already available");

        uint256 remainingTime = parkingSpots[spotId].leaseEndTime > block.timestamp
            ? parkingSpots[spotId].leaseEndTime - block.timestamp
            : 0;
        uint256 refund = (remainingTime * parkingSpots[spotId].rentalFee) /
            (parkingSpots[spotId].leaseEndTime - (parkingSpots[spotId].leaseEndTime - remainingTime));

        payable(parkingSpots[spotId].renter).transfer(refund);

        delete parkingSpots[spotId].leaseInfo;
        delete parkingSpots[spotId].rentalFee;
        delete parkingSpots[spotId].leaseEndTime;
        parkingSpots[spotId].isAvailable = true;
        parkingSpots[spotId].renter = address(0);

        emit LeaseTerminated(spotId, refund);
    }

    // 查询车位信息
    function getSpotInfo(uint256 spotId) public view returns (ParkingSpot memory) {
        return parkingSpots[spotId];
    }

    // 提款租赁费用
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner()).transfer(balance);
    }
}
