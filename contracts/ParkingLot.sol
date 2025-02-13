// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ParkingLot
 * @dev 车位合约，用于管理车位NFT的铸造、租赁、退租、撤销等操作
 */
contract ParkingLot is ERC721Burnable, Ownable {
    /**
     * @notice 车位信息结构体
     * @param id 车位ID
     * @param name 车位名称
     * @param picture 车位图片
     * @param location 车位地址
     * @param owner 车位所有者
     * @param renter 租户地址
     * @param rent_end_time 租赁结束时间
     * @param rent_price 租金（单位：wei）
     * @param latitude 纬度
     * @param longitude 经度
     * @param create_time 创建时间
     * @param update_time 更新时间
     * @dev 该结构体用于存储车位的相关信息
     */
    struct ParkingSpot {
        uint256 id;           // 车位ID
        string name;          // 车位名称
        string picture;       // 车位图片
        string location;      // 车位名称或地址
        address owner;        // 车位所有者
        address renter;       // 租户地址
        uint256 rent_end_time;// 租赁结束时间
        uint256 rent_price;   // 租金（单位：wei）
        int256 latitude;      // 纬度
        int256 longitude;     // 经度
        uint256 create_time;  // 创建时间
        uint256 update_time;  // 更新时间
    }

    // 车位ID到车位信息的映射
    mapping(uint256 => ParkingSpot) public parkingSpots;

    // 已铸造的车位总数
    uint256 public totalSupply;

    uint256 public nextTokenId = 1;

    // 构造函数
    constructor() ERC721("ParkingSpotNFT", "PSNFT") Ownable(msg.sender) {
        transferOwnership(msg.sender);  // 设置初始所有者
    }

    // 铸造车位NFT
    function mint(
        string memory name,
        string memory picture,
        string memory location,
        uint256 rentPrice,
        int256 longitude,
        int256 latitude
    ) public {
        uint256 tokenId = nextTokenId;
        nextTokenId++; // 递增，保证ID连续

        parkingSpots[tokenId] = ParkingSpot({
            id: tokenId,
            name: name,
            picture: picture,
            owner: msg.sender,
            location: location,
            renter: address(0),
            rent_end_time: 0,
            rent_price: rentPrice,
            latitude: latitude,
            longitude: longitude,
            create_time: block.timestamp,
            update_time: block.timestamp
        });

        _mint(msg.sender, tokenId);
        totalSupply++;
    }

    // 租赁车位
    function rent(uint256 tokenId, uint256 duration) public payable {
        address owner = ownerOf(tokenId); // 存储所有者，减少重复调用
        require(owner != address(0), "Car spot does not exist");

        ParkingSpot storage spot = parkingSpots[tokenId];

        require(spot.renter == address(0) || block.timestamp > spot.rent_end_time, "Spot is already rented");

        // 计算租金（从人民币转换成 ETH）
        uint256 totalRent = spot.rent_price * duration;
        require(msg.value >= totalRent, "Insufficient payment");

        spot.renter = msg.sender;
        spot.rent_end_time = block.timestamp + (duration * 1 days); // 计算租赁结束时间

        // 将租金转给车位所有者
        (bool success, ) = payable(owner).call{value: msg.value}("");
        require(success, "Transfer failed");
    }


    // 退租车位
    function terminateRental(uint256 tokenId) public {
        ParkingSpot storage spot = parkingSpots[tokenId];
        require(ownerOf(tokenId) != address(0), "Parking spot does not exist");
        require(msg.sender == spot.renter, "Only the renter can terminate the rental");

        // 退租逻辑
        spot.renter = address(0);
        spot.rent_end_time = 0;

        // 可选择退款逻辑：按租赁时长计算未使用时间的租金
        uint256 unusedTime = spot.rent_end_time - block.timestamp;
        uint256 refundAmount = (spot.rent_price * unusedTime) / (spot.rent_end_time - block.timestamp);
        payable(msg.sender).transfer(refundAmount);
    }

    // 撤销车位
    function revokeParkingSpot(uint256 tokenId) public onlyOwner {
        require(ownerOf(tokenId) != address(0), "Parking spot does not exist");
        ParkingSpot storage spot = parkingSpots[tokenId];
        require(spot.renter!=address(0) || block.timestamp > spot.rent_end_time, "Spot is currently rented");

        delete parkingSpots[tokenId]; // 先删除车位信息
        _burn(tokenId);// 销毁NFT并删除车位信息
        totalSupply--;  // 维护正确的总量
    }

    // 检查车位租赁状态
    function checkRentalStatus(uint256 tokenId) public view returns (bool) {
        ParkingSpot memory spot = parkingSpots[tokenId];
        return spot.renter!=address(0) && block.timestamp <= spot.rent_end_time;
    }

    // 获取所有车位信息
    function getAllParkingSpots() public view returns (ParkingSpot[] memory) {
        uint count = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (parkingSpots[i].id != 0) {
                count++;
            }
        }

        ParkingSpot[] memory spots = new ParkingSpot[](count);
        uint index = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (parkingSpots[i].id != 0) {
                spots[index] = parkingSpots[i];
                index++;
            }
        }

        return spots;
    }

    // 获取我的车位（所有者或者租用的）
    function getMyParkingSpots() public view returns (ParkingSpot[] memory) {
        uint count = 0;

        // 先统计符合条件的车位数量
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (parkingSpots[i].id != 0 && (parkingSpots[i].owner == msg.sender || parkingSpots[i].renter == msg.sender)) {
                count++;
            }
        }

        // 只分配需要的空间，避免浪费
        ParkingSpot[] memory spots = new ParkingSpot[](count);
        uint index = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (parkingSpots[i].id != 0 && (parkingSpots[i].owner == msg.sender || parkingSpots[i].renter == msg.sender)) {
                spots[index] = parkingSpots[i];
                index++;
            }
        }

        return spots;
    }

    // 更新自己的车位信息
    function updateParkingSpot(
        uint256 tokenId,
        string memory name,
        string memory picture,
        string memory location,
        uint256 rentPrice,
        int256 longitude,
        int256 latitude
    ) public {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can update the parking spot");

        ParkingSpot storage spot = parkingSpots[tokenId];
        spot.name = name;
        spot.picture = picture;
        spot.location = location;
        spot.rent_price = rentPrice;
        spot.longitude = longitude;
        spot.latitude = latitude;
        spot.update_time = block.timestamp;
    }
}
