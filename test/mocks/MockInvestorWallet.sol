pragma solidity ^0.4.15;

import '../../contracts/InvestorWallet.sol';

contract MockInvestorWallet is InvestorWallet {
  uint256 public timeStamp;

  function MockInvestorWallet(
      address _wpr,
      address _exchanger,
      uint256 _monthsToRelease
  ) InvestorWallet(_wpr, _exchanger, _monthsToRelease) {
    timeStamp = now;
  }

  function getTime() internal returns (uint256) {
    return timeStamp;
  }

  function setBlockTimestamp(uint256 _timeStamp) public {
    timeStamp = _timeStamp;
  }
}
