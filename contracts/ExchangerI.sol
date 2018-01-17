pragma solidity ^0.4.15;

import "zeppelin-solidity/contracts/token/ERC20Basic.sol";


contract ExchangerI {
  ERC20Basic public wpr;

  /// @notice This method should be called by the WCT holders to collect their
  ///  corresponding WPRs
  function collect(address caller) public;
}
