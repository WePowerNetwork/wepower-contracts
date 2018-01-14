pragma solidity ^0.4.15;

import "./ERC20.sol";
import "./MiniMeToken.sol";
import "./SafeMath.sol";
import "./ExchangerI.sol";


// 1. WePower deploy a contract which is controlled by WePower multisig.
// 2. Investor transfer eth or any other currency to WePower multisig or some bank.
// 3. WePower mints WCT2 to that investor contract wallet.
// 4. Investor contract wallet stores WCT2.
// 5. WePower transfers ownership to Investor multisig.
// 6. Investor can only claim tokens after X months defined on the contract deployment.

contract InvestorWallet is Controlled {
  using SafeMath for uint256;
  ERC20 wpr;
  ExchangerI exchanger;
  uint256 releaseTime;

  function InvestorWallet(address _wpr, address _exchanger, uint256 _monthsToRelease) {
    wpr = ERC20(_wpr);
    exchanger = ExchangerI(_exchanger);
    releaseTime = getTime().add(months(_monthsToRelease));
  }

  function () public onlyController {
    collectTokens();
  }

  /// @notice The Dev (Owner) will call this method to extract the tokens
  function collectTokens() public onlyController {
    require(getTime() > releaseTime);

    exchanger.collect();

    require(wpr.transfer(controller, wpr.balanceOf(address(this))));
    TokensWithdrawn(controller, balance);
  }

  function getTime() internal returns (uint256) {
    return now;
  }

  function months(uint256 m) internal returns (uint256) {
      return m.mul(30 days);
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyController {
    require(_token != address(wct2));

    if (_token == 0x0) {
      controller.transfer(this.balance);
      return;
    }

    ERC20 token = ERC20(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(controller, balance);
    ClaimedTokens(_token, controller, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event TokensWithdrawn(address indexed _holder, uint256 _amount);
}
