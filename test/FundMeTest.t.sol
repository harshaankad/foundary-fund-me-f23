//When we run tests in foundry without giving an rpc-url it by default runs a anvil chain
//hence proper command to run is forge test -vv --fork-url 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//listen here 
//Two times problem has occurred because of not giving the correct path
//As remappings is not working see the proper path from under FOUNDRY-FUND-ME-F3

import {Test,console} from "lib/forge-std/src/Test.sol";
//Mandatory to import for every test file
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import{HelperConfig} from "../script/HelperConfig.s.sol";
//import {HelperConfig} from "../../script/HelperConfig.s.sol";
//console is used to use console.log which is sort of print function
//foundry-23/foundry-fund-me-f23/src/FundMe.sol
contract FundMeTest is Test{

    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 SEND_VALUE=0.1 ether;//100000000000000000
    uint256 STARTING_BALANCE=10 ether;
    uint256 GAS_PRICE=1;


    function setUp() external{//Always runs first
       DeployFundMe deployFundMe=new DeployFundMe();
       fundMe=deployFundMe.run();
       vm.deal(USER,STARTING_BALANCE);//This sets up the money in the wallet address of user to 10 ether
    }
    
    function testMinimumDollarIsFive() public{
        //assertEq takes in two parameters and checks if the first parameter is equal to the second parameter
        assertEq(fundMe.MINIMUM_USD(),5e18);
        //to access MINIMUM_USD we create a contract variable fundme and then use the above syntax
       }

    function testOwnerIsMessageSender() public{
        assertEq(fundMe.i_owner(),msg.sender);
        //address(this) indicates address if FundMeTest contract
    }

    function testPriceFeedVersionIsAccurate() public{
        uint256 version=fundMe.getVersion();
        assertEq(version,4);
        //When we run tests in foundry without giving an rpc-url it by default runs a anvil chain
        //hence proper command to run is forge test -vv --fork-url 
        //take this fork-url from Alchemy 
    }

    function testFundFailWithoutEnoughEth()public{
        vm.expectRevert();//hey if the next line is false test passes else the test fails (ulta)
        fundMe.fund();//By default 0 is passed which is less than 5 doller thus condition fils so test passes
        //to send value we use fundMe.fund(10e18) which is equivalent to sending 10 Eth;

    }
    
    function testFundUpdatesFundedDataStructure() public {
       fundMe.fund{value:SEND_VALUE}();
       uint256 amountFunded=fundMe.getAddressToAmountFunded(address(this));
       assertEq(amountFunded,SEND_VALUE);

    }

    function testAddsFunderToArrayOfFunders() public {
        //vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        //vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, address(this));//here msg.sender is FundMeTest.t.sol contract
    }

     function testOnlyOwnerCanWithdraw() public {
      
       fundMe.fund{value: SEND_VALUE}();
       vm.expectRevert();
       fundMe.withdraw();

    }

   /* modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }*/
     function testWithdrawFromASingleFunder() public {
        // Arrange
        fundMe.fund{value: SEND_VALUE}();
        uint256 startingFundMeBalance = address(fundMe).balance;//Balance of the contract that is sending money
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        // // Act
        
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }
      function testWithDrawFromMultipleFunders() public {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;//uint160 used when we want to work with addresses
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();//Anything between start and stop prank will be pretended to be called by fundme.getOwner()
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }
}



/*pragma solidity 0.8.19;

import {Test,console} from "lib/forge-std/src/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import{HelperConfig} from "../script/HelperConfig.s.sol";
contract FundMeTest is StdCheats, Test {
    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether; // just a value to make sure we are sending enough!
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    // uint256 public constant SEND_VALUE = 1e18;
    // uint256 public constant SEND_VALUE = 1_000_000_000_000_000_000;
    // uint256 public constant SEND_VALUE = 1000000000000000000;

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        (fundMe, helperConfig) = deployer.run();
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testPriceFeedSetCorrectly() public {
        address retreivedPriceFeed = address(fundMe.getPriceFeed());
        // (address expectedPriceFeed) = helperConfig.activeNetworkConfig();
        address expectedPriceFeed = helperConfig.activeNetworkConfig();
        assertEq(retreivedPriceFeed, expectedPriceFeed);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    // https://twitter.com/PaulRBerg/status/1624763320539525121

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    // Can we do our withdraw function a cheaper way?
    function testWithDrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
        assert((numberOfFunders + 1) * SEND_VALUE == fundMe.getOwner().balance - startingOwnerBalance);
    }
}*/