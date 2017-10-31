pragma solidity ^0.4.15;

import '../../contracts/InvestorWallet.sol';

contract MockInvestorWallet is InvestorWallet {
  uint256 public timeStamp;

  function MockInvestorWallet(
      address _wct2,
      uint256 _monthsToRelease
  ) InvestorWallet(_wct2, _monthsToRelease) {
    timeStamp = now;
  }

  function getTime() internal returns (uint256) {
    return timeStamp;
  }

  function setBlockTimestamp(uint256 _timeStamp) public {
    timeStamp = _timeStamp;
  }
}
