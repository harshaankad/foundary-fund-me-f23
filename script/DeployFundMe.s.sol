//to deploy we use command forge script sript/filename.s.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployFundMe is Script{
    function run() external returns(FundMe){

        //Before startBroadcast not a real transaction,less gas
        HelperConfig helperconfig=new HelperConfig();
        address ethUsdPriceFeed=helperconfig.activeNetworkConfig();//As we are returning struct we have to wrap it in parentheses
        //If multiple returns items are there we have to separate them using commas

        vm.broadcast();
        //After startBroadcast real transaction.more gas
        FundMe fundme=new FundMe(ethUsdPriceFeed);
        return fundme;
    }
}