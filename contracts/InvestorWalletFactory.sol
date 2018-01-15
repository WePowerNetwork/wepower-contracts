pragma solidity ^0.4.15;

import "./InvestorWallet.sol";

contract InvestorWalletFactory {
  function createInvestorWallet(
      address _wpr,
      address _exchanger,
      uint256 _monthsToRelease,
      address _investor
  ) returns (InvestorWallet) {
    InvestorWallet newWallet = new InvestorWallet(
      _wpr,
      _exchanger,
      _monthsToRelease
    );

    newWallet.changeController(_investor);
    return newWallet;
  }
}
