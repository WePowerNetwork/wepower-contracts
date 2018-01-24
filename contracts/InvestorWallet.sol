pragma solidity ^0.4.15;

import "./SafeMath.sol";
import "./ExchangerI.sol";
import "./InvestorWalletFactoryI.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/token/ERC20Basic.sol";


// 1. WePower deploy a contract which is controlled by WePower multisig.
// 2. Investor transfer eth or any other currency to WePower multisig or some bank.
// 3. WePower mints WCT2 to that investor contract wallet.
// 4. Investor contract wallet stores WCT2.
// 5. WePower transfers ownership to Investor multisig.
// 6. Investor can only claim tokens after X months defined on the contract deployment.

contract InvestorWallet is Ownable {
  using SafeMath for uint256;
  address internal wct2;
  InvestorWalletFactoryI internal factory;
  uint256 public releaseTime;

  function InvestorWallet(address _wct2, address _factory, uint256 _monthsToRelease) {
    wct2 = _wct2;
    factory = InvestorWalletFactoryI(_factory);
    releaseTime = getTime().add(months(_monthsToRelease));
  }

  function () public onlyOwner {
    exchangeTokens();
    collectTokens();
  }

  function exchangeTokens() public onlyOwner {
    ExchangerI exchanger = ExchangerI(factory.exchanger());

    require(address(exchanger) != 0x0);
    exchanger.collect(address(this));
  }

  /// @notice The Dev (Owner) will call this method to extract the tokens
  function collectTokens() public onlyOwner {
    require(getTime() > releaseTime);
    ExchangerI exchanger = ExchangerI(factory.exchanger());
    require(address(exchanger) != 0x0);
    ERC20Basic wpr = ERC20Basic(exchanger.wpr());
    uint256 balance = wpr.balanceOf(address(this));
    require(wpr.transfer(owner, balance));
    TokensWithdrawn(owner, balance);
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

  /// @notice This method can be used by the owner to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
    ExchangerI exchanger = ExchangerI(factory.exchanger());
    require(address(exchanger) != 0x0);
    ERC20Basic wpr = ERC20Basic(exchanger.wpr());
    require(_token != address(wct2) && _token != address(wpr));

    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20Basic token = ERC20Basic(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _owner, uint256 _amount);
  event TokensWithdrawn(address indexed _holder, uint256 _amount);
}
