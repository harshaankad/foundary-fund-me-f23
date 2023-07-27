//Instead of everytime giving an sepolia id 
//This is a easier way to test our code locally
//Deploy mocks when we are on anvil chain
//Keep track of contract addresses across different chains

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{
    //If we are on a local anvil we deploy mocks
    //otherwise grab the existing address from live network

     uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed; //ETH-USD price feed address
    }

    NetworkConfig public activeNetworkConfig;

    constructor(){
        if(block.chainid==11155111){//Every bloackchain network has its unique chain id
            activeNetworkConfig=getSepoliaEthConfig();
        }
        else if(block.chainid==1){
            activeNetworkConfig=getMainNetEthConfig();
        }
        else{
            activeNetworkConfig=getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig()public pure returns (NetworkConfig memory){//we use memory keyword as this is a special object
        NetworkConfig memory sepoliaConfig=NetworkConfig({priceFeed:0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
    }

    function getMainNetEthConfig()public pure returns (NetworkConfig memory){//we use memory keyword as this is a special object
        NetworkConfig memory ethConfig=NetworkConfig({priceFeed:0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethConfig;
    }

     function getOrCreateAnvilEthConfig()public returns (NetworkConfig memory){
        if(activeNetworkConfig.priceFeed!=address(0)){//Checks if activenetworkconfig is already set to some address like sepolia address ,if not sets it to anvil
            return activeNetworkConfig;
        }
        //1) Deploy the mock
        //2)Return the mock address
        vm.broadcast();
        MockV3Aggregator mockPriceFeed=new MockV3Aggregator(DECIMALS,INITIAL_PRICE);//Thix ix similar to the price feed to which we pass address
        //vm.stopBroadcast();

        NetworkConfig memory anvilConfig=NetworkConfig({priceFeed:address(mockPriceFeed)});
        return anvilConfig;
        
    }
}