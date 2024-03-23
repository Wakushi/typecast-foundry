// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {TypecastRegistry} from "../src/TypecastRegistry.sol";

contract DeployTypecastRegistry is Script {
    function run() external returns (TypecastRegistry) {
        vm.startBroadcast();
        TypecastRegistry typecastRegistry = new TypecastRegistry();
        vm.stopBroadcast();

        return typecastRegistry;
    }
}
