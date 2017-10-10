pragma solidity ^0.4.15;

import "./MiniMeToken.sol";
import "./WPR.sol";

contract Contribution is Ownable {
  using SafeMath for uint256;

  WPR public wpr;
  bool public transferable;
  address public contributionWallet;
  address public futureHolder;
  address public devHolder;
  address public communityHolder;

  uint256 public totalWeiCap;             // Total Wei to be collected
  uint256 public totalWeiCollected;       // How much Wei has been collected
  uint256 public weiPreCollected;

  uint256 public minimumPerTransaction = 0.01 ether;

  uint256 public numWhitelistedInvestors;
  mapping (address => bool) public canPurchase;
  mapping (address => uint256) public individualWeiCollected;

  uint256 public startTime;
  uint256 public endTime;

  uint256 public initializedTime;
  uint256 public finalizedTime;

  uint256 public initializedBlock;
  uint256 public finalizedBlock;

  bool public paused;

  modifier initialized() {
    assert(initializedBlock != 0);
    _;
  }

  modifier contributionOpen() {
    assert(getBlockTimestamp() >= startTime &&
           getBlockTimestamp() <= endTime &&
           finalizedTime == 0);
    _;
  }

  modifier notPaused() {
    require(!paused);
    _;
  }

  function Contribution(address _wpr) {
    require(_wpr != 0x0);
    wpr = WPR(_wpr);
  }

  function initialize(
      address _wct,
      address _wct1,
      address _exchanger,
      address _contributionWallet,
      address _futureHolder,
      address _devHolder,
      address _communityHolder,
      uint256 _totalWeiCap,
      uint256 _startTime,
      uint256 _endTime
  ) public onlyOwner {
    // Initialize only once
    require(initializedBlock == 0);
    require(initializedTime == 0);
    assert(wpr.totalSupply() == 0);
    assert(wpr.owner() == address(this));
    assert(wpr.decimals() == 18);  // Same amount of decimals as ETH

    require(_contributionWallet != 0x0);
    contributionWallet = _contributionWallet;

    require(_futureHolder != 0x0);
    futureHolder = _futureHolder;

    require(_devHolder != 0x0);
    devHolder = _devHolder;

    require(_communityHolder != 0x0);
    communityHolder = _communityHolder;

    assert(_startTime >= getBlockTimestamp());
    require(_startTime < _endTime);
    startTime = _startTime;
    endTime = _endTime;

    require(_totalWeiCap > 0);
    totalWeiCap = _totalWeiCap;

    initializedBlock = getBlockNumber();
    initializedTime = getBlockTimestamp();

    require(_wct != 0x0);
    require(_wct1 != 0x0);
    require(_exchanger != 0x0);

    weiPreCollected = MiniMeToken(_wct).totalSupplyAt(initializedBlock);
    weiPreCollected = weiPreCollected.add(
      MiniMeToken(_wct1).totalSupplyAt(initializedBlock)
    );

    // Exchangerate from wct to wpr 2500 considering 25% bonus.
    require(wpr.mint(_exchanger, weiPreCollected.mul(2500)));

    Initialized(initializedBlock);
  }

  /// @notice interface for founders to blacklist investors
  /// @param _investors array of investors
  function blacklistAddresses(address[] _investors) public onlyOwner {
    for (uint256 i = 0; i < _investors.length; i++) {
      blacklist(_investors[i]);
    }
  }

  /// @notice interface for founders to whitelist investors
  /// @param _investors array of investors
  function whitelistAddresses(address[] _investors) public onlyOwner {
    for (uint256 i = 0; i < _investors.length; i++) {
      whitelist(_investors[i]);
    }
  }

  function whitelist(address investor) public onlyOwner {
    if (canPurchase[investor]) return;
    numWhitelistedInvestors++;
    canPurchase[investor] = true;
  }

  function blacklist(address investor) public onlyOwner {
    if (!canPurchase[investor]) return;
    numWhitelistedInvestors--;
    canPurchase[investor] = false;
  }

  // ETH-WPR exchange rate
  function exchangeRate() constant public initialized returns (uint256 rate) {

    if (getBlockTimestamp() <= startTime + 1 hours) {
      // 15% Bonus
      rate = 2300;
    } else if (getBlockTimestamp() <= startTime + 2 hours) {
      // 10% Bonus
      rate = 2200;
    } else {
      rate = 2000;
    }
  }

  function tokensToGenerate(uint256 toFund) internal returns (uint256) {
    return toFund.mul(exchangeRate());
  }

  /// @notice If anybody sends Ether directly to this contract, consider he is
  /// getting WPRs.
  function () public payable notPaused {
    proxyPayment(msg.sender);
  }

  //////////
  // TokenController functions
  //////////

  /// @notice This method will generally be called by the WPR token contract to
  ///  acquire WPRs. Or directly from third parties that want to acquire WPRs in
  ///  behalf of a token holder.
  /// @param _th WPR holder where the WPRs will be minted.
  function proxyPayment(address _th) public payable notPaused initialized contributionOpen returns (bool) {
    require(_th != 0x0);
    doBuy(_th);
    return true;
  }

  function onTransfer(address, address, uint256) public returns (bool) {
    return transferable;
  }

  function onApprove(address, address, uint256) public returns (bool) {
    return transferable;
  }

  function allowTransfers(bool _transferable) onlyOwner {
    transferable = _transferable;
  }

  function doBuy(address _th) internal {
    // whitelisting only during the first day
    if (getBlockTimestamp() <= startTime + 1 days) {
      require(canPurchase[_th]);
    }
    require(msg.value >= minimumPerTransaction);
    uint256 toFund = msg.value;
    uint256 toCollect = weiToCollect();

    if (toCollect > 0) {
      // Check total supply cap reached, sell the all remaining tokens
      if (toFund > toCollect) {
        toFund = toCollect;
      }
      uint256 tokensGenerated = tokensToGenerate(toFund);
      require(tokensGenerated > 0);
      require(wpr.mint(_th, tokensGenerated));

      contributionWallet.transfer(toFund);
      individualWeiCollected[_th] = individualWeiCollected[_th].add(toFund);
      totalWeiCollected = totalWeiCollected.add(toFund);
      NewSale(_th, toFund, tokensGenerated);
    } else {
      toFund = 0;
    }

    uint256 toReturn = msg.value.sub(toFund);
    if (toReturn > 0) {
      _th.transfer(toReturn);
    }
  }

  /// @dev Internal function to determine if an address is a contract
  /// @param _addr The address being queried
  /// @return True if `_addr` is a contract
  function isContract(address _addr) constant internal returns (bool) {
    if (_addr == 0) return false;
    uint256 size;
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }

  /// @notice This method will can be called by the controller before the contribution period
  ///  end or by anybody after the `endTime`. This method finalizes the contribution period
  ///  by creating the remaining tokens and transferring the controller to the configured
  ///  controller.
  function finalize() public initialized {
    require(finalizedBlock == 0);
    require(finalizedTime == 0);
    require(getBlockTimestamp() >= startTime);
    require(msg.sender == owner || getBlockTimestamp() > endTime || weiToCollect() == 0);

    // WPR generated so far is 51% of total
    uint256 tokenCap = wpr.totalSupply().mul(100).div(55);
    // dev Wallet will have 20% of the total Tokens and will be able to retrieve
    // after a year.
    wpr.mint(devHolder, tokenCap.mul(20).div(100));
    // community Wallet will have access to 10% of the total Tokens.
    wpr.mint(communityHolder, tokenCap.mul(10).div(100));
    // future Wallet will have 20% of the total Tokens and will be able to retrieve
    // after a year.
    wpr.mint(futureHolder, tokenCap.mul(15).div(100));

    require(wpr.finishMinting());

    finalizedBlock = getBlockNumber();
    finalizedTime = getBlockTimestamp();

    Finalized(finalizedBlock);
  }

  //////////
  // Constant functions
  //////////

  /// @return Total eth that still available for collection in weis.
  function weiToCollect() public constant returns(uint256) {
    return totalWeiCap > totalWeiCollected ? totalWeiCap.sub(totalWeiCollected) : 0;
  }

  //////////
  // Testing specific methods
  //////////

  /// @notice This function is overridden by the test Mocks.
  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }

  function getBlockTimestamp() internal constant returns (uint256) {
    return block.timestamp;
  }

  //////////
  // Safety Methods
  //////////

  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
    if (wpr.owner() == address(this)) {
      wpr.claimTokens(_token);
    }

    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20 token = ERC20(_token);
    uint256 balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  /// @notice Pauses the contribution if there is any issue
  function pauseContribution(bool _paused) onlyOwner {
    paused = _paused;
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event NewSale(address indexed _th, uint256 _amount, uint256 _tokens);
  event Initialized(uint _now);
  event Finalized(uint _now);
}
