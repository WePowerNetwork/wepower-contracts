pragma solidity ^0.4.15;

import "./InvestorWallet.sol";
import "./InvestorWalletFactoryI.sol";

contract InvestorWalletFactory is InvestorWalletFactoryI, Controlled {
  MiniMeToken wct2;

  function InvestorWalletFactory(address _wct) {
    wct2 = MiniMeToken(_wct);
  }

  function createInvestorWallet(
      address _wpr,
      uint256 _monthsToRelease,
      address _investor,
      uint256 _amount
  ) onlyController returns (InvestorWallet) {
    InvestorWallet newWallet = new InvestorWallet(
      _wpr,
      address(this),
      _monthsToRelease
    );

    newWallet.changeController(_investor);
    wct2.generateTokens(newWallet, _amount);
    return newWallet;
  }

  function setExchanger(address _exchanger) public onlyController {
    exchanger = _exchanger;
  }

  function retrieveWCT2() public onlyController {
    wct2.changeController(msg.sender);
  }
}
