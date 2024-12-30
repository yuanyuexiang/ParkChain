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
    }

    mapping(uint256 => ParkingSpot) public parkingSpots;

    event SpotCreated(uint256 id, address owner);
    event SpotLeased(uint256 id, string leaseInfo, uint256 rentalFee, uint256 leaseEndTime);
    event SpotReleased(uint256 id);

    constructor() ERC721("ParkingLotNFT", "PLNFT") {}

    // 创建车位 NFT
    function createSpot() public {
        _spotIdCounter.increment();
        uint256 newSpotId = _spotIdCounter.current();
        parkingSpots[newSpotId] = ParkingSpot(newSpotId, msg.sender, true, "", 0, 0);
        _mint(msg.sender, newSpotId);
        emit SpotCreated(newSpotId, msg.sender);
    }

    // 租赁车位
    function leaseSpot(uint256 spotId, string memory leaseInfo, uint256 rentalFee, uint256 duration) public payable {
        require(parkingSpots[spotId].isAvailable, "Spot is not available");
        require(msg.value == rentalFee, "Incorrect rental fee");

        parkingSpots[spotId].isAvailable = false;
        parkingSpots[spotId].leaseInfo = leaseInfo;
        parkingSpots[spotId].rentalFee = rentalFee;
        parkingSpots[spotId].leaseEndTime = block.timestamp + duration;

        emit SpotLeased(spotId, leaseInfo, rentalFee, parkingSpots[spotId].leaseEndTime);
    }

    // 释放车位
    function releaseSpot(uint256 spotId) public {
        require(msg.sender == parkingSpots[spotId].owner, "Only owner can release the spot");
        require(!parkingSpots[spotId].isAvailable, "Spot is already available");
        require(block.timestamp >= parkingSpots[spotId].leaseEndTime, "Lease period is not over yet");

        parkingSpots[spotId].isAvailable = true;
        parkingSpots[spotId].leaseInfo = ""; // 清除租赁信息
        parkingSpots[spotId].rentalFee = 0; // 清除租赁费用
        parkingSpots[spotId].leaseEndTime = 0; // 清除租赁结束时间

        emit SpotReleased(spotId);
    }

    // 查询车位信息
    function getSpotInfo(uint256 spotId) public view returns (ParkingSpot memory) {
        return parkingSpots[spotId];
    }

    // 提款租赁费用
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
