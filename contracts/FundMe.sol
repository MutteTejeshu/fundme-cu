// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {

    function getPrice() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF);
        (/*uint80 roundId*/, int256 answer, /*uint256 startedAt*/, /*uint256 updatedAt*/, /*uint80 answeredInRound*/) = priceFeed.latestRoundData();
        return uint256(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount) internal view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    function getVersion() internal view returns (uint256) {
        return AggregatorV3Interface(0xfEefF7c3fB57d18C5C6Cdd71e45D2D0b4F9377bF).version();
    }

}

error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        
        require(msg.value.getConversionRate() >= MINIMUM_USD, "didn't send enough ETH");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value;

    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Must be owner");
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);

        //transfer
        //send
        //call

        // payable(msg.sender).transfer(address(this).balance);

        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        (bool callSuccess, /* bytes memory dataReturned */) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");

    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner!");
        if(msg.sender != i_owner) {revert NotOwner();}
        _;
        // it comes back here and executes if anything else is present here
    }

    receive() external payable {
        fund();
     }

    fallback() external payable {
        fund();
    }


}