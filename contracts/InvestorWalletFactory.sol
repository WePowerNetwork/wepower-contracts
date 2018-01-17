pragma solidity ^0.4.15;

import "./InvestorWallet.sol";
import "./InvestorWalletFactoryI.sol";
import "./MiniMeToken.sol";

contract InvestorWalletFactory is InvestorWalletFactoryI, Ownable {
  MiniMeToken public wct2;

  function InvestorWalletFactory(address _wct2) public {
    wct2 = MiniMeToken(_wct2);
  }

  function createInvestorWallet(
      uint256 _monthsToRelease,
      address _investor,
      uint256 _amount
  ) onlyOwner returns (InvestorWallet) {
    InvestorWallet newWallet = new InvestorWallet(
      address(wct2),
      address(this),
      _monthsToRelease
    );

    newWallet.transferOwnership(_investor);
    wct2.generateTokens(newWallet, _amount);
    return newWallet;
  }

  function setExchanger(address _exchanger) public onlyOwner {
    exchanger = _exchanger;
  }

  function retrieveWCT2() public onlyOwner {
    wct2.changeController(msg.sender);
  }
}
