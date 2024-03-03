// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMaestry} from "../src/NFTMaestry.sol";

contract NFTMaestryScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address key = vm.addr(privateKey);
        console.log("Key", key);

        vm.startBroadcast(privateKey);

        new NFTMaestry();

        vm.stopBroadcast();        
    }
}
