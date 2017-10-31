pragma solidity ^0.4.15;

import '../../contracts/TeamTokenHolder.sol';

contract MockTeamTokenHolder is TeamTokenHolder {
  uint256 public timeStamp;

  function MockTeamTokenHolder(
      address _controller,
      address _contribution,
      address _wpr
  ) TeamTokenHolder(_controller, _contribution, _wpr) {
    timeStamp = now;
  }

  function getTime() internal returns (uint256) {
    return timeStamp;
  }

  function setBlockTimestamp(uint256 _timeStamp) public {
    timeStamp = _timeStamp;
  }
}
