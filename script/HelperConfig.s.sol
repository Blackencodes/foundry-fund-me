//SPDX-License-Identifier: MIT

// Deploy mocks when we are on a local anvil chain
// Keep track of contract addresses across different chains
// Sepolia ETH/USD
// Mainet ETH/USD

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {Vm} from "forge-std/Vm.sol";

contract HelperConfig {

    NetworkConfig public activeNetworkconfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    Vm public constant vm = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

    struct NetworkConfig {
        address priceFeed; //ETH/USD pricefeed Address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkconfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkconfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        NetworkConfig memory SepoliaConfig = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return SepoliaConfig;
    }
    
    function getAnvilEthConfig() public returns(NetworkConfig memory) {
        if (activeNetworkconfig.priceFeed != address(0)) {
            return activeNetworkconfig;
        }   
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory AnvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});

        return AnvilConfig;
    }
}
