//SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
//import {MockV3Aggregator} from "../mock/MockV3Aggregator.sol";

contract FundMeTest is Test {
   // MockV3Aggregator mockPriceFeed;
    FundMe fundMe;

    address USER = makeAddr("user");
    
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1e9;

    function setUp() external {
        //fundMe = new FundMe();
        //mockPriceFeed = new MockV3Aggregator(2000 * 10**8);
        vm.deal(USER, STARTING_BALANCE);
    //fundMe = new FundMe(address(mockPriceFeed));
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        
    }
    function testDemo() view public {
        assertEq(fundMe.minimumUsd(), 5e18);
    }
    function testOwnerIsMsgSender() view public{
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //function testGetVersion() view public{
      //  assertEq(fundMe.getVersion(), 4);
   // }

    function testFundFail() public {
        vm.expectRevert();
        fundMe.fund();
        //fundMe.fund{value: 100}();
        //assertEq(fundMe.addressToAmountFunded(msg.sender), 100);
    }   

    function testFundUpdatesFundedDataStructure() public {
        
        vm.prank(USER);
        
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunders(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;

    }

    function testOnlyOwnerCanWithdraw() public  funded{
        vm.prank(USER);

        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawWithMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = gasStart - gasEnd;


        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeBalance, fundMe.getOwner().balance);

        
    }
}