pragma solidity ^0.4.15;

import "./InvestorWallet.sol";
import "./InvestorWalletFactoryI.sol";

contract InvestorWalletFactory is InvestorWalletFactoryI, Ownable {
  function createInvestorWallet(
      address _wpr,
      uint256 _monthsToRelease,
      address _investor,
      uint256 _amount
  ) onlyOwner returns (InvestorWallet) {
    InvestorWallet newWallet = new InvestorWallet(
      _wpr,
      address(this),
      _monthsToRelease
    );

    newWallet.changeController(_investor);
    _wct2.generateTokens(newWallet, _amount);
    return newWallet;
  }

  function setExchanger(address _exchanger) public onlyOwner {
    exchanger = _exchanger;
  }

  function retrieveWCT2() public onlyOwner {
    _wct2.changeController(msg.sender);
  }
}
