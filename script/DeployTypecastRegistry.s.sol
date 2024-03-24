// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {TypecastRegistry} from "../src/TypecastRegistry.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployTypecastRegistry is Script {
    function run() external returns (TypecastRegistry) {
        HelperConfig helperConfig = new HelperConfig();
        (, , , , , , address priceFeed, , ) = helperConfig
            .activeNetworkConfig();

        vm.startBroadcast();
        TypecastRegistry typecastRegistry = new TypecastRegistry(priceFeed);
        vm.stopBroadcast();

        return typecastRegistry;
    }
}
