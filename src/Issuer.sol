// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { OwnerIsCreator } from "@chainlink/contracts/src/v0.8/shared/access/OwnerIsCreator.sol";
import { FunctionsClient } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { FunctionsRequest } from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import { ParkLotToken } from "./ParkLotToken.sol";

/**
 * @author  CoheeYang.
 * @title   IssuerContract.
 * @dev     key function: issue & fulfillRequest.
 * @notice  The issuer contract uses chainlink function to make a request to get
 *          information of the park lot.
 *          The fulfillRequest function will handle the response and mint the token.
 */
contract Issuer is FunctionsClient, OwnerIsCreator {
    using FunctionsRequest for FunctionsRequest.Request;

    error argumentLengthError();
    error LatestIssueInProgress();

    struct Parklot_Nft {
        address to;
        uint256 amount;
    }

    ParkLotToken internal immutable parklotToken;
    string internal sourceCode;
    bytes32 internal lastRequestId;
    uint256 private nextTokenId;
    mapping(bytes32 requestId => Parklot_Nft) internal issuesInProgress;

    constructor(
        address tokenAddress,
        address functionsRouterAddress,
        string memory _sourceCode
    ) FunctionsClient(functionsRouterAddress) {
        parklotToken = ParkLotToken(tokenAddress);
        sourceCode = _sourceCode;
    }

    function issue(
        address to,
        string[] memory args,///用户id
        uint256 amount, ///发行数量 1
        uint64 subscriptionId,///订阅id
        uint32 gasLimit,
        bytes32 donID
    ) external onlyOwner returns (bytes32 requestId) {
        if (lastRequestId != bytes32(0)) revert LatestIssueInProgress();

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(sourceCode);
        if (args.length == 1) {
            req.setArgs(args);
        } else {
            revert argumentLengthError();
        }

        requestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);

        issuesInProgress[requestId] = Parklot_Nft(to, amount);

        lastRequestId = requestId;
    }

    function cancelPendingRequest() external onlyOwner {
        lastRequestId = bytes32(0);
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length != 0) {
            revert(string(err));
        }

        if (lastRequestId == requestId) {
            string memory tokenURI = string(response);

            uint256 tokenId = nextTokenId++;
            Parklot_Nft memory parklot_Nft = issuesInProgress[requestId];

            parklotToken.mint(parklot_Nft.to, tokenId, parklot_Nft.amount, "", tokenURI);

            lastRequestId = bytes32(0);
        }
    }
}
