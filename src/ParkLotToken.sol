// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { OwnerIsCreator } from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";

/**
 * @author  CoheeYang.
 * @title   ParkLotToken.
 * @notice  Use this contract to manage tokenId and URI while mint and burn
 *          relevant tokens.
 */
contract ParkLotToken is ERC1155, OwnerIsCreator {
    address internal issuer;
    mapping(uint256 tokenId => string) private _tokenURIs;
    event SetIssuer(address indexed issuer);
    error ERC1155Core_CallerIsNotIssuerOrItself(address msgSender);
    modifier onlyIssuerOrItself() {
        if (msg.sender != address(this) && msg.sender != issuer) {
            revert ERC1155Core_CallerIsNotIssuerOrItself(msg.sender);
        }
        _;
    }

    constructor(string memory uri_) ERC1155(uri_) {}

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data,
        string memory _tokenUri
    ) public onlyIssuerOrItself {
        _mint(_to, _id, _amount, _data);
        _tokenURIs[_id] = _tokenUri;
    }

    function burn(address account, uint256 id, uint256 amount) public onlyIssuerOrItself {
        if (account != _msgSender() && !isApprovedForAll(account, _msgSender())) {
            revert ERC1155MissingApprovalForAll(_msgSender(), account);
        }

        _burn(account, id, amount);
    }

    function setIssuer(address _issuer) external onlyOwner {
        issuer = _issuer;

        emit SetIssuer(_issuer);
    }

    function setURI(uint256 tokenId, string memory tokenURI) internal {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        return bytes(tokenURI).length > 0 ? tokenURI : super.uri(tokenId);
    }
}
