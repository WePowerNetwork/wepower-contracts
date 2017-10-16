pragma solidity ^0.4.15;

import "./Contribution.sol";

contract CommunityTokenHolder is Ownable {
  using SafeMath for uint256;

  Contribution contribution;
  ERC20 wrp;
  uint256 public collectedTokens;

  function RemainderTokenHolder(address _owner, address _contribution, address _wrp) {
    owner = _owner;
    contribution = Contribution(_contribution);
    wrp = ERC20(_wrp);
  }

  /// @notice The Dev (Owner) will call this method to extract the tokens
  function collectTokens() public onlyOwner {
    uint256 balance = wrp.balanceOf(address(this));
    uint256 total = collectedTokens.add(balance);

    uint256 finalizedTime = contribution.finalizedTime();

    require(finalizedTime > 0 && getTime() > finalizedTime.add(months(6)));

    uint256 canExtract = total.mul(getTime().sub(finalizedTime)).div(months(12));

    canExtract = canExtract.sub(collectedTokens);

    if (canExtract > balance) {
      canExtract = balance;
    }

    collectedTokens = collectedTokens.add(canExtract);
    assert(wrp.transfer(owner, canExtract));

    TokensWithdrawn(owner, canExtract);
  }

  function months(uint256 m) internal returns (uint256) {
      return m.mul(30 days);
  }

  function getTime() internal returns (uint256) {
    return now;
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
    require(_token != address(wrp));
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20 token = ERC20(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event TokensWithdrawn(address indexed _holder, uint256 _amount);
}
