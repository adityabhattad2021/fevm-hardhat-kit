// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MarketAPI} from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FilecoinInsurance {

    using SafeMath for uint256;

    event NewInsuranceRegistered(
        address indexed insuranceHolder,
        uint256 indexed dealId,
        uint256 indexed FILPrice
    );

    event InsuranceClaimed(
        address indexed insuranceHolder,
        uint256 indexed dealId,
        uint256 indexed FILPrice,
        uint256 amountPaid
    );

    struct Deal{
        string dealLabel;
        uint64 dealClientActorId;
        uint64 dealProviderActorId;
        bool isDealActive;
        MarketTypes.GetDealClientCollateralReturn dealClientCollateral;
    }
    mapping(uint=>Deal) public dealIdToDeal;

    struct Insurance {
        address insuranceHolder;
        uint64 dealId;
        uint64 FILPrice;
        uint256 collateralLocked;
        uint256 coverageLimit;
        uint64 coveragePercentage;
        uint256 premium;
        uint256 totalAmountClaimed;
        uint256 InsuranceExpiry;
    }
    mapping(address => Insurance) public holderToInsurance;
    address[] public insuranceHolders; 

    function getDeal(uint64 dealId) public {
        string memory dealLabel=MarketAPI.getDealLabel(dealId).label;
        uint64 dealClientActorId=MarketAPI.getDealClient(dealId).client;
        uint64 dealProviderActorId=MarketAPI.getDealProvider(dealId).provider;
        bool isDealActive=MarketAPI.getDealVerified(dealId).verified;
        MarketTypes.GetDealClientCollateralReturn memory dealClientCollateral=MarketAPI.getDealClientCollateral(dealId);
        dealIdToDeal[dealId]=Deal({
            dealLabel:dealLabel,
            dealClientActorId:dealClientActorId,
            dealProviderActorId:dealProviderActorId,
            isDealActive:isDealActive,
            dealClientCollateral:dealClientCollateral
        });
    }


// Current Sample Insurance Plan:
    // 1. coverageLimit=10FIL
    // 2. coveragePercentage=70%
    // 3. premium=1FIL
    function registerInsurance(uint64 dealId,uint64 FILToDollar) payable public {
        getDeal(dealId);
        Deal memory newDeal=dealIdToDeal[dealId];
        require(newDeal.isDealActive,"Deal is not active");
        // 1000000000000000000=1 FIL
        require(msg.value<1000000000000000000,"Need to send one 1FIL");
        // TODO: Check if the msg.sender is the storage provider in the deal.
        holderToInsurance[msg.sender]=Insurance({
            insuranceHolder:msg.sender,
            dealId:dealId,
            FILPrice:FILToDollar,
            collateralLocked:50000000000000000000, // 50 FIL (TODO: Get the real value of the collateral locked).
            coverageLimit:10000000000000000000, // 10 FIL
            premium:1000000000000000000, // 1 FIL
            coveragePercentage:70,
            totalAmountClaimed:0,
            InsuranceExpiry:block.timestamp+5 minutes
        });
        insuranceHolders.push(msg.sender);

        emit NewInsuranceRegistered(
            msg.sender,
            dealId,
            FILToDollar
        );
    }

    function calculateLosses(uint64 currentFILPrice,uint256 collateralLocked,uint64 oldFILPrice) public pure returns(uint256 totalPayableInFIL){
        uint256 oldAmount = collateralLocked.mul(oldFILPrice);
        uint256 newAmount = collateralLocked.mul(currentFILPrice);
        uint256 losses=oldAmount.sub(newAmount);
        require(losses>0,"There were no losses");
        uint256 percentToBePaid=losses.mul(70).div(100);  // 70% of the total losses.
        totalPayableInFIL=percentToBePaid.div(currentFILPrice);
    }


    function claim(uint dealId,uint64 currentFILPrice) public {
        Deal memory newDeal=dealIdToDeal[dealId];
        require(newDeal.isDealActive,"Deal is not active");
        Insurance storage insuranceData=holderToInsurance[msg.sender];
        uint64 oldFILPrice=insuranceData.FILPrice;
        require(currentFILPrice>oldFILPrice,"Current FIL Price < Old FIL Price");
        uint256 collateralLocked=insuranceData.collateralLocked;
        uint256 totalPayable=calculateLosses(currentFILPrice,collateralLocked,oldFILPrice);
        insuranceData.totalAmountClaimed+=totalPayable;
        (bool success,)=payable(msg.sender).call{value:totalPayable}("");
        require(success,"Payment failed");

        emit InsuranceClaimed(
            msg.sender,
            dealId,
            currentFILPrice,
            totalPayable
        );
    }


}