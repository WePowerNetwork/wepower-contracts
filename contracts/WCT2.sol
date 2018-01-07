pragma solidity ^0.4.15;


import "./MiniMeToken.sol";


/**
 * @title WePower Contribution Token
 *
 * @dev Simple ERC20 Token, with pre-sale logic
 * @dev IMPORTANT NOTE: do not use or deploy this contract as-is. It needs some changes to be
 * production ready.
 */
contract WCT2 is MiniMeToken {
  /**
    * @dev Constructor
  */
  function WCT2(address _tokenFactory)
    MiniMeToken(
      _tokenFactory,
      0x0,                     // no parent token
      0,                       // no snapshot block number from parent
      "WePower Contribution Token 2", // Token name
      18,                      // Decimals
      "WCT2",                   // Symbol
      true                     // Enable transfers
    ) {}
}
