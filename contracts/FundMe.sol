// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// using import before (with npm)
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    address public owner;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    //constructor gets called immediately after contract is deployed
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        // $50 minimum value
        uint256 minimumUSD = 50 * 10**18; // ** bdeutet ^

        // bad practise:
        // if(msg.value < minimumUSD) {
        //     revert?

        // better: (if require statement is not met, code will stop executing)
        require(getConversionRate(msg.value) >= minimumUSD, "Spend more ETH");

        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        //we want to work in a different currency than ETH
        //conversion rate? -> CL DON
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // Komma fuer nicht benutzte Variablen im Tupel
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // to get it to 18 decimals (in wei) - eth hat 8 nachkommstellen, darum noch mit 10 ** 10 multiplizieren
        // 2435,46093121 - ETH/USD price - better start applying to McDonalds
    }

    // 1 gewi = 1000000000 wei
    // eth amount in wei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethAmount * ethPrice) / 1000000000000000000;
        return ethAmountInUSD;
        // 0.000002399400000000 - price of 1 gewi in USD
    }

    modifier onlyOwner() {
        // we only want contract owner to be able to withdraw - modifier for many different functions
        // == is solidty for true/false
        require(msg.sender == owner, "Fick Dich");
        _; // first require statement and then run the code
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0); //reset array
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }
}
