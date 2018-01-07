pragma solidity ^0.4.15;

import "zeppelin-solidity/contracts/token/MintableToken.sol";
import "zeppelin-solidity/contracts/token/PausableToken.sol";

/**
 * @title WePower Contribution Token
 */
contract WPR is MintableToken, PausableToken {
  string constant public name = "WePower Token";
  string constant public symbol = "WPR";
  uint constant public decimals = 18;

  function WPR() {
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20 token = ERC20(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

  function disown() public onlyOwner {
    OwnershipTransferred(owner, address(0));
    owner = address(0);
  }
}
