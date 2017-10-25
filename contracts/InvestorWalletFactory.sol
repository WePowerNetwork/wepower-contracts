pragma solidity ^0.4.15;

import "./InvestorWallet.sol";

contract InvestorWalletFactory {
  function createInvestorWallet(
      address _wct2,
      uint256 _monthsToRelease,
      address _investor
  ) returns (InvestorWallet) {
    InvestorWallet newWallet = new InvestorWallet(
      _wct2,
      _monthsToRelease
    );

    newWallet.changeController(_investor);
    return newWallet;
  }
}