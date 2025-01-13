// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ParkingNFT is ERC721Burnable, Ownable {
    // 车位结构体
    struct ParkingSpot {
        uint256 id;           // 车位ID
        string location;      // 车位名称或地址
        bool isRented;        // 是否已租赁
        address renter;       // 租户地址
        uint256 rentEndTime;  // 租赁结束时间
        uint256 rentPrice;    // 租金（单位：wei）
        int256 latitude;      // 纬度
        int256 longitude;     // 经度
    }

    // 车位ID到车位信息的映射
    mapping(uint256 => ParkingSpot) public parkingSpots;

    // 已铸造的车位总数
    uint256 public totalSupply;

    // 构造函数
    constructor(address initialOwner) ERC721("ParkingSpotNFT", "PSNFT") Ownable(msg.sender) {
        transferOwnership(initialOwner);  // 设置初始所有者
    }

    // 铸造车位NFT
    function mint(
        address to,
        string memory location,
        uint256 rentPrice,
        int256 latitude,
        int256 longitude
    ) public onlyOwner {
        require(latitude >= -90 && latitude <= 90, "Invalid latitude");
        require(longitude >= -180 && longitude <= 180, "Invalid longitude");

        uint256 tokenId = totalSupply + 1;
        parkingSpots[tokenId] = ParkingSpot({
            id: tokenId,
            location: location,
            isRented: false,
            renter: address(0),
            rentEndTime: 0,
            rentPrice: rentPrice,
            latitude: latitude,
            longitude: longitude
        });

        _mint(to, tokenId);
        totalSupply++;
    }

    // 租赁车位
    function rent(uint256 tokenId, uint256 duration) public payable {
        ParkingSpot storage spot = parkingSpots[tokenId];
        require(ownerOf(tokenId) != address(0), "Car spot does not exist");
        require(!spot.isRented || block.timestamp > spot.rentEndTime, "Spot is already rented");
        require(msg.value >= spot.rentPrice, "Insufficient payment");

        spot.isRented = true;
        spot.renter = msg.sender;
        spot.rentEndTime = block.timestamp + duration;

        // 转账租金给车位所有者
        payable(ownerOf(tokenId)).transfer(msg.value);
    }

    // 退租车位
    function terminateRental(uint256 tokenId) public {
        ParkingSpot storage spot = parkingSpots[tokenId];
        require(ownerOf(tokenId) != address(0), "Parking spot does not exist");
        require(spot.isRented, "Parking spot is not rented");
        require(msg.sender == spot.renter, "Only the renter can terminate the rental");

        // 退租逻辑
        spot.isRented = false;
        spot.renter = address(0);
        spot.rentEndTime = 0;

        // 可选择退款逻辑：按租赁时长计算未使用时间的租金
        uint256 unusedTime = spot.rentEndTime - block.timestamp;
        uint256 refundAmount = (spot.rentPrice * unusedTime) / (spot.rentEndTime - block.timestamp);
        payable(msg.sender).transfer(refundAmount);
    }

    // 撤销车位
    function revokeParkingSpot(uint256 tokenId) public onlyOwner {
        require(ownerOf(tokenId) != address(0), "Parking spot does not exist");
        ParkingSpot storage spot = parkingSpots[tokenId];
        require(!spot.isRented || block.timestamp > spot.rentEndTime, "Spot is currently rented");

        // 销毁NFT并删除车位信息
        _burn(tokenId);
        delete parkingSpots[tokenId];
    }

    // 检查车位租赁状态
    function checkRentalStatus(uint256 tokenId) public view returns (bool) {
        ParkingSpot memory spot = parkingSpots[tokenId];
        return spot.isRented && block.timestamp <= spot.rentEndTime;
    }

    // 获取所有车位信息
    function getAllParkingSpots() public view returns (ParkingSpot[] memory) {
        ParkingSpot[] memory spots = new ParkingSpot[](totalSupply);

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (ownerOf(i) != address(0)) {
                spots[i - 1] = parkingSpots[i];
            }
        }

        return spots;
    }
}
