// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
        address priceFeed;
        address ccipRouter;
        bytes32 donId;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 11155420) {
            activeNetworkConfig = getSepoliaOptimismConfig();
        } else if (block.chainid == 84532) {
            activeNetworkConfig = getSepoliaBaseConfig();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployerKey: vm.envUint("PRIVATE_KEY"),
                priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
                ccipRouter: 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59,
                donId: bytes32("fun-ethereum-sepolia-1")
            });
    }

    function getSepoliaOptimismConfig()
        public
        view
        returns (NetworkConfig memory)
    {
        return
            NetworkConfig({
                vrfCoordinator: 0x0000000000000000000000000000000000000000,
                gasLane: 0x0,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
                deployerKey: vm.envUint("PRIVATE_KEY"),
                priceFeed: 0x61Ec26aA57019C486B10502285c5A3D4A4750AD7,
                ccipRouter: 0x114A20A10b43D4115e5aeef7345a1A71d2a60C57,
                donId: bytes32("unknown")
            });
    }

    function getSepoliaBaseConfig() public view returns (NetworkConfig memory) {
        return
            NetworkConfig({
                vrfCoordinator: 0x0000000000000000000000000000000000000000,
                gasLane: 0x0,
                subscriptionId: 0,
                callbackGasLimit: 500000,
                link: 0xE4aB69C077896252FAFBD49EFD26B5D171A32410,
                deployerKey: vm.envUint("PRIVATE_KEY"),
                priceFeed: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1,
                ccipRouter: 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93,
                donId: bytes32("unknown")
            });
    }
}
