pragma solidity ^0.4.15;

import '../../contracts/FutureTokenHolder.sol';

contract MockFutureTokenHolder is FutureTokenHolder {
  uint256 public timeStamp;

  function MockFutureTokenHolder(address _controller, address _contribution, address _wpr)
    FutureTokenHolder(_controller, _contribution, _wpr)
  {
    timeStamp = now;
  }

  function getTime() internal returns (uint256) {
    return timeStamp;
  }

  function setBlockTimestamp(uint256 _timeStamp) public {
    timeStamp = _timeStamp;
  }
}
