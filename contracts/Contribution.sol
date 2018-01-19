pragma solidity ^0.4.15;

import "./MiniMeToken.sol";
import "./ExchangerI.sol";
import "./WPR.sol";

contract Contribution is Ownable {
  using SafeMath for uint256;

  WPR public wpr;
  address public contributionWallet;
  address public teamHolder;
  address public communityHolder;
  address public futureHolder;
  address public exchanger;

  // Wings Integration
  uint256 public totalCollected;

  uint256 public totalWeiCap;             // Total Wei to be collected
  uint256 public totalWeiCollected;       // How much Wei has been collected
  uint256 public presaleTokensIssued;

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
    require(initializedBlock != 0);
    _;
  }

  modifier contributionOpen() {
    require(getBlockTimestamp() >= startTime &&
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
      address _wct2,
      address _exchanger,
      address _contributionWallet,
      address _futureHolder,
      address _teamHolder,
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
    wpr.pause();

    require(_contributionWallet != 0x0);
    contributionWallet = _contributionWallet;

    require(_futureHolder != 0x0);
    futureHolder = _futureHolder;

    require(_teamHolder != 0x0);
    teamHolder = _teamHolder;

    require(_communityHolder != 0x0);
    communityHolder = _communityHolder;

    require(_startTime >= getBlockTimestamp());
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

    presaleTokensIssued = MiniMeToken(_wct).totalSupplyAt(initializedBlock);
    presaleTokensIssued = presaleTokensIssued.add(
      MiniMeToken(_wct1).totalSupplyAt(initializedBlock)
    );
    presaleTokensIssued = presaleTokensIssued.add(
      MiniMeToken(_wct2).totalSupplyAt(initializedBlock)
    );

    // Exchange rate from wct to wpr 1250 considering 25% bonus.
    require(wpr.mint(_exchanger, presaleTokensIssued.mul(1250)));
    exchanger = _exchanger;

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
  function exchangeRate() constant public initialized returns (uint256) {
    return 1000;
  }

  function tokensToGenerate(uint256 toFund) internal returns (uint256 generatedTokens) {
    generatedTokens = generatedTokens.add(toFund.mul(exchangeRate()));
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
    if (msg.value == 0) {
      wpr.unpause();
      ExchangerI(exchanger).collect(_th);
      wpr.pause();
    } else {
      doBuy(_th);
    }
    return true;
  }

  function doBuy(address _th) internal {
    // whitelisting only during the first day
    if (getBlockTimestamp() <= startTime + 1 days) {
      require(canPurchase[_th]);
    }
    require(msg.value >= minimumPerTransaction);
    uint256 toFund = msg.value;
    uint256 toCollect = weiToCollectByInvestor(_th);

    require(toCollect > 0);

    // Check total supply cap reached, sell the all remaining tokens
    if (toFund > toCollect) {
      toFund = toCollect;
    }
    uint256 tokensGenerated = tokensToGenerate(toFund);
    require(tokensGenerated > 0);
    require(wpr.mint(_th, tokensGenerated));

    contributionWallet.transfer(toFund);
    // Wings Integration
    totalCollected = totalCollected.add(toFund);
    individualWeiCollected[_th] = individualWeiCollected[_th].add(toFund);
    totalWeiCollected = totalWeiCollected.add(toFund);
    NewSale(_th, toFund, tokensGenerated);

    uint256 toReturn = msg.value.sub(toFund);
    if (toReturn > 0) {
      _th.transfer(toReturn);
    }
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

    // WPR generated so far is 55% of total
    uint256 tokenCap = wpr.totalSupply().mul(100).div(55);
    // team Wallet will have 20% of the total Tokens and will be in a 12 months
    // vesting contract with 6 months cliff.
    wpr.mint(teamHolder, tokenCap.mul(20).div(100));
    // community Wallet will have access to 10% of the total Tokens.
    wpr.mint(communityHolder, tokenCap.mul(10).div(100));
    // future Wallet will have 15% of the total Tokens and will be able to retrieve
    // after a year.
    wpr.mint(futureHolder, tokenCap.mul(15).div(100));

    require(wpr.finishMinting());
    wpr.transferOwnership(owner);

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

  /// @return Total eth that still available for collection in weis.
  function weiToCollectByInvestor(address investor) public constant returns(uint256) {
    uint256 cap;
    uint256 collected;
    // adding 1 day as a placeholder for X hours.
    // This should change into a variable or coded into the contract.
    if (getBlockTimestamp() <= startTime + 5 hours) {
      cap = totalWeiCap.div(numWhitelistedInvestors);
      collected = individualWeiCollected[investor];
    } else {
      cap = totalWeiCap;
      collected = totalWeiCollected;
    }
    return cap > collected ? cap.sub(collected) : 0;
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

  // Wings Integration
  // This function can be used by the contract owner to add ether collected
  // outside of this contract, such as from a presale
  function setTotalCollected(uint _totalCollected) public onlyOwner {
    totalCollected = _totalCollected;
  }

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
