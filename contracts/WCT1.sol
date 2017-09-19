pragma solidity ^0.4.15;


import "./MiniMeToken.sol";


/**
 * @title WePower Contribution Token
 *
 * @dev Simple ERC20 Token, with pre-sale logic
 * @dev IMPORTANT NOTE: do not use or deploy this contract as-is. It needs some changes to be
 * production ready.
 */
contract WCT1 is MiniMeToken {
  /**
    * @dev Constructor
  */
  function WCT1(address _tokenFactory)
    MiniMeToken(
      _tokenFactory,
      0x0,                     // no parent token
      0,                       // no snapshot block number from parent
      "WePower Contribution Token", // Token name
      18,                      // Decimals
      "WCT1",                   // Symbol
      true                     // Enable transfers
    ) {}
}
