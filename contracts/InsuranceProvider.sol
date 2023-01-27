// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MarketAPI} from "@zondax/filecoin-solidity/contracts/v0.8/MarketAPI.sol";
import {MarketTypes} from "@zondax/filecoin-solidity/contracts/v0.8/types/MarketTypes.sol";


contract InsuranceProvider {

    struct Deal {
        uint dealId;
        uint price;
        bool status;
    }

    mapping(uint => Deal) public deals;

    function registerStorageDeal(uint dealId) public {
        // Verify that the deal is active
        // Get current price of the FIL token while applying for the insurance to store along the deal.
        // If yes stores the deal in the deals mapping.
        // If no, throw an error.
        // TODO: Implement this function.
    }

    function claimInsurance(uint dealId) public {
        // Verify the current chainlink price of the FIL token, either on front-end or if possible on the smart contract.
        // If the price is lower than the price when the deal was registered, then the insurance is paid.
    }

    function payPremuim(uint dealId) public {
        // Pay the premium for the insurance.
    }

    function calcualateLosses(uint dealId) public {
        // Calculate the losses based on the current price of the FIL token and the price when the deal was registered.
    }

    function getDeal(uint dealId) public {
        // Get the deal from the deals mapping.
    }


    function getDealPrice(uint dealId) public {
        // Get the price of the deal from the deals mapping.
    }


    function getDealStatus(uint dealId) public {
        // Get the status of the deal from the deals mapping.
    }
    


}