pragma solidity ^0.4.15;

contract ExchangerI {
  /// @notice This method should be called by the WCT holders to collect their
  ///  corresponding WPRs
  function collect(address caller) public;
}
