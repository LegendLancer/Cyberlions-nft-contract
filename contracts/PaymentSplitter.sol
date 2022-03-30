// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract RevenueSplitter is PaymentSplitter {
    uint public payeeCount;
    constructor(address[] memory payees_, uint[] memory shares_) PaymentSplitter(payees_, shares_) {
        payeeCount = payees_.length;
    }

    function releaseAll() external {
        for (uint i = 0; i < payeeCount; i++) {
            // do something
            release(payee(i));
        }
    }
}