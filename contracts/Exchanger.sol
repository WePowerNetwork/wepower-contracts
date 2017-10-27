pragma solidity ^0.4.15;

/*
  Copyright 2017, Klaus Hott (BlockChainLabs.nz)
  Copyright 2017, Jordi Baylina (Giveth)

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/// @title Exchanger Contract
/// @author Klaus Hott
/// @dev This contract will be used to distribute WPR between WCT holders.
///  WCT token is not transferable, and we just keep an accounting between all tokens
///  deposited and the tokens collected.

import "./Contribution.sol";
import "./ExchangerI.sol";

contract Exchanger is ExchangerI, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) public collected;
  uint256 public totalCollected;
  MiniMeToken public wct;
  MiniMeToken public wct1;
  MiniMeToken public wct2;
  ERC20 public wpr;
  Contribution public contribution;

  function Exchanger(address _wct, address _wct1, address _wct2, address _wpr, address _contribution) {
    wct = MiniMeToken(_wct);
    wct1 = MiniMeToken(_wct1);
    wct2 = MiniMeToken(_wct2);
    wpr = ERC20(_wpr);
    contribution = Contribution(_contribution);
  }

  /// @notice This method should be called by the WCT holders to collect their
  ///  corresponding WPRs
  function collect(address caller) public {
    // WCT sholder could collect WPR right after contribution started
    assert(getBlockTimestamp() > contribution.startTime());

    uint256 pre_sale_fixed_at = contribution.initializedBlock();

    // Get current WPR ballance at contributions initialization-
    uint256 balance = wct.balanceOfAt(caller, pre_sale_fixed_at);
    balance = balance.add(wct1.balanceOfAt(caller, pre_sale_fixed_at));
    balance = balance.add(wct2.balanceOfAt(caller, pre_sale_fixed_at));

    uint totalSupplied = wct.totalSupplyAt(pre_sale_fixed_at);
    totalSupplied = totalSupplied.add(wct1.totalSupplyAt(pre_sale_fixed_at));
    totalSupplied = totalSupplied.add(wct2.totalSupplyAt(pre_sale_fixed_at));

    // total of wpr to be distributed.
    uint256 total = totalCollected.add(wpr.balanceOf(address(this)));

    // First calculate how much correspond to him
    uint256 amount = total.mul(balance).div(totalSupplied);

    // And then subtract the amount already collected
    amount = amount.sub(collected[caller]);

    // Notify the user that there are no tokens to exchange
    require(amount > 0);

    totalCollected = totalCollected.add(amount);
    collected[caller] = collected[caller].add(amount);

    assert(wpr.transfer(caller, amount));

    TokensCollected(caller, amount);
  }

  //////////
  // Testing specific methods
  //////////

  /// @notice This function is overridden by the test Mocks.
  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }

  /// @notice This function is overridden by the test Mocks.
  function getBlockTimestamp() internal constant returns (uint256) {
    return block.timestamp;
  }

  //////////
  // Safety Method
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
    assert(_token != address(wpr));
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
  event TokensCollected(address indexed _holder, uint256 _amount);
}
