const MockContribution = artifacts.require("MockContribution.sol");
const WPR = artifacts.require("WPR.sol");
const WCT1 = artifacts.require("WCT1.sol");
const WCT2 = artifacts.require("WCT2.sol");
const TeamTokenHolder = artifacts.require("TeamTokenHolder.sol");
const FutureTokenHolder = artifacts.require("FutureTokenHolder.sol");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const Exchanger = artifacts.require("MockExchanger");
const assert = require("chai").assert;
const BigNumber = web3.BigNumber;
import { expectThrow, duration, latestBlock, getTime } from "./utils.js";

contract("Pause", ([miner, owner, investor, investor2]) => {
  let wpr;
  let contribution;
  let exchanger;
  let wct1;
  let wct2;
  let tokensPreSold = new BigNumber(10 ** 18 * 50);
  let totalCap;
  let sendingAmount;
  let currentTime;
  let futureHolder;
  let teamHolder;
  let _communityHolder;
  let latestBlockNumber;

  beforeEach(async function() {
    const tokenFactory = await MiniMeTokenFactory.new();
    wct1 = await WCT1.new(tokenFactory.address);
    wct2 = await WCT2.new(tokenFactory.address);
    await wct1.generateTokens(owner, tokensPreSold);
    wpr = await WPR.new();
    contribution = await MockContribution.new(wpr.address);
    exchanger = await Exchanger.new(
      wct1.address,
      wct2.address,
      wpr.address,
      contribution.address
    );

    totalCap = new BigNumber(1000 * 10 ** 18); //1000 eth
    sendingAmount = new BigNumber(10 ** 18); // 1 eth
    currentTime = getTime();
    futureHolder = await FutureTokenHolder.new(
      owner,
      contribution.address,
      wpr.address
    );
    teamHolder = await TeamTokenHolder.new(
      owner,
      contribution.address,
      wpr.address
    );
    _communityHolder = "0x0039F22efB07A647557C7C5d17854CFD6D489eF3";

    latestBlockNumber = await latestBlock();

    await contribution.setBlockTimestamp(currentTime);
    await contribution.setBlockNumber(latestBlockNumber);
    await wpr.transferOwnership(contribution.address);

    await contribution.whitelist(owner);
    await contribution.whitelist(investor);

    await contribution.initialize(
      wct1.address,
      wct2.address,
      exchanger.address,
      owner,
      futureHolder.address,
      teamHolder.address,
      _communityHolder,
      totalCap,
      currentTime + 1,
      currentTime + 10
    );
    await contribution.setBlockTimestamp(currentTime + 2);
    await exchanger.setBlockTimestamp(currentTime + 2);
  });

  it("tokens should be paused once they are sold", async function() {
    await contribution.sendTransaction({
      from: investor,
      value: web3.toWei(1, "ether")
    });
    let balance = await wpr.balanceOf(investor);
    assert.equal(balance.toNumber(), 4000 * 10 ** 18);
    await expectThrow(wpr.transfer(owner, 10, { from: investor }));
  });

  it("tokens should be unpaused once crowdsale is finalized (By the owner)", async function() {
    await contribution.sendTransaction({
      from: investor,
      value: web3.toWei(1, "ether")
    });
    await expectThrow(wpr.transfer(investor2, 10, { from: investor }));

    await expectThrow(wpr.unpause());
    await contribution.finalize();
    await wpr.unpause();

    await expectThrow(wpr.disown({ from: investor2 }));

    await wpr.pause();
    await wpr.unpause();
    await wpr.disown();

    await expectThrow(wpr.pause());

    await wpr.transfer(investor2, 600 * 10 ** 18, {
      from: investor
    });
    let balance = await wpr.balanceOf(investor);
    assert.equal(balance.toNumber(), 3400 * 10 ** 18);
    balance = await wpr.balanceOf(investor2);
    assert.equal(balance.toNumber(), 600 * 10 ** 18);
  });
});
