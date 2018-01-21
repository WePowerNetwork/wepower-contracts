pragma solidity ^0.4.15;

import '../../contracts/Exchanger.sol';

contract MockExchanger is Exchanger {
  uint256 public timeStamp;

  function MockExchanger(
      address _wct1,
      address _wct2,
      address _wpr,
      address _contribution
  ) Exchanger(_wct1, _wct2, _wpr, _contribution) {
    timeStamp = now;
  }

  function getBlockTimestamp() internal constant returns (uint256) {
    return timeStamp;
  }

  function setBlockTimestamp(uint256 _timeStamp) public {
    timeStamp = _timeStamp;
  }
}
