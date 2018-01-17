const MockContribution = artifacts.require("MockContribution.sol");
const WPR = artifacts.require("WPR.sol");
const WCT = artifacts.require("WCT.sol");
const WCT1 = artifacts.require("WCT1.sol");
const WCT2 = artifacts.require("WCT2.sol");
const TeamTokenHolder = artifacts.require("TeamTokenHolder.sol");
const FutureTokenHolder = artifacts.require("FutureTokenHolder.sol");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const Exchanger = artifacts.require("MockExchanger");
const assert = require("chai").assert;
const BigNumber = web3.BigNumber;
import { expectThrow, duration, latestBlock, getTime } from "./utils.js";

contract("Contribution", ([miner, owner, investor]) => {
  let wpr;
  let contribution;
  let exchanger;
  let wct;
  let wct1;
  let wct2;
  let tokensPreSold = new BigNumber(10 ** 18 * 50);
  let bonusCap;
  let totalCap;
  let sendingAmount;
  let currentTime;
  let futureHolder;
  let teamHolder;
  let _communityHolder;
  let latestBlockNumber;

  it("#constructor accepts Token address", async function() {
    const contribution = await MockContribution.new(
      "0x0000000000000000000000000000000000000123"
    );
    const tokenAddress = await contribution.wpr();
    assert.equal(
      tokenAddress,
      "0x0000000000000000000000000000000000000123",
      "== token address"
    );
  });

  describe("#initialize", async function() {
    beforeEach(async function() {
      const tokenFactory = await MiniMeTokenFactory.new();
      wct = await WCT.new(tokenFactory.address);
      wct1 = await WCT1.new(tokenFactory.address);
      wct2 = await WCT2.new(tokenFactory.address);
      await wct.generateTokens(owner, tokensPreSold);
      wpr = await WPR.new();
      contribution = await MockContribution.new(wpr.address);
      exchanger = await Exchanger.new(
        wct.address,
        wct1.address,
        wct2.address,
        wpr.address,
        contribution.address
      );

      totalCap = new BigNumber(1000 * 10 ** 18); //1000 eth
      bonusCap = totalCap.div(10);
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

      await contribution.whitelist(miner);
      await contribution.initialize(
        wct.address,
        wct1.address,
        wct2.address,
        exchanger.address,
        owner,
        futureHolder.address,
        teamHolder.address,
        _communityHolder,
        bonusCap,
        totalCap,
        currentTime + 1,
        currentTime + 10
      );
    });

    it("Values after initialization are ok", async function() {
      //public values
      const contributionWallet = await contribution.contributionWallet();
      const totalSupplyCap = await contribution.totalWeiCap();
      const totalSold = await contribution.totalWeiCollected();
      const startTime = await contribution.startTime();
      const endTime = await contribution.endTime();
      const initializedTime = await contribution.initializedTime();
      const finalizedTime = await contribution.finalizedTime();
      const initializedBlock = await contribution.initializedBlock();
      const finalizedBlock = await contribution.finalizedBlock();
      const paused = await contribution.paused();
      const minimumPerTransaction = await contribution.minimumPerTransaction();

      // check that exchanger received tokens from PreSale APT

      const exchangerBalance = await wpr.balanceOf(exchanger.address);
      const wctSupplyAt = await wct.totalSupplyAt(latestBlockNumber);
      const wct1SupplyAt = await wct1.totalSupplyAt(latestBlockNumber);
      const wct2SupplyAt = await wct2.totalSupplyAt(latestBlockNumber);

      assert.equal(
        exchangerBalance.toString(10),
        wctSupplyAt
          .add(wct1SupplyAt)
          .add(wct2SupplyAt)
          .mul(1250)
          .toString(10)
      );

      assert.equal(contributionWallet, owner);
      assert.equal(totalSupplyCap.toNumber(), totalCap);
      assert.equal(totalSold.toString(10), "0");
      assert.equal(startTime.toNumber(), currentTime + 1);
      assert.equal(endTime.toNumber(), currentTime + 10);
      assert.equal(initializedTime.toNumber(), currentTime);
      assert.equal(finalizedTime.toNumber(), 0);
      assert.equal(initializedBlock.toNumber(), latestBlockNumber);
      assert.equal(finalizedBlock.toNumber(), 0);
      assert.equal(paused, false);
      assert.equal(minimumPerTransaction.toString(), web3.toWei(0.01, "ether"));
    });

    it("Testing empty transaction to contribution and Purchase", async function() {
      const wctSupplyAt = await wct.totalSupplyAt(latestBlockNumber);
      const wct1SupplyAt = await wct1.totalSupplyAt(latestBlockNumber);
      const wct2SupplyAt = await wct2.totalSupplyAt(latestBlockNumber);
      const wprInExchanger = wctSupplyAt
        .add(wct1SupplyAt)
        .add(wct2SupplyAt)
        .mul(1250);
      const exchangerBalance = await wpr.balanceOf(exchanger.address);
      assert.equal(exchangerBalance.toNumber(), wprInExchanger.toNumber());
      let ownerBalance = await wpr.balanceOf(owner);
      assert.equal(ownerBalance.toNumber(), 0);
      await contribution.setBlockTimestamp(currentTime + 2);
      await exchanger.setBlockTimestamp(currentTime + 2);
      await contribution.sendTransaction({ from: owner });
      ownerBalance = await wpr.balanceOf(owner);
      assert.equal(ownerBalance.toNumber(), wprInExchanger.toNumber());

      await contribution.sendTransaction({
        from: miner,
        value: new BigNumber(10 ** 18)
      });

      let minerBalance = await wpr.balanceOf(miner);
      assert.equal(minerBalance.toNumber(), 1150 * 10 ** 18);

      await contribution.sendTransaction({
        from: miner,
        value: new BigNumber(100 * 10 ** 18)
      });

      minerBalance = await wpr.balanceOf(miner);
      assert.equal(
        minerBalance.toNumber(),
        new BigNumber(1150 * 100 * 10 ** 18).add(1000 * 10 ** 18).toNumber() // 100 eth with bonus 1 eth without bonus
      );
    });

    it("Admin can set the totalCollected amount for wings integration", async function() {
      assert.equal((await contribution.totalCollected.call()).toNumber(), 0);
      await contribution.setTotalCollected(web3.toWei(1, "ether"));
      assert.equal(
        (await contribution.totalCollected.call()).toNumber(),
        web3.toWei(1, "ether")
      );
    });

    it("Wings integration keeps track of ether collected", async function() {
      const wctSupplyAt = await wct.totalSupplyAt(latestBlockNumber);
      const wct1SupplyAt = await wct1.totalSupplyAt(latestBlockNumber);
      const wct2SupplyAt = await wct2.totalSupplyAt(latestBlockNumber);
      const wprInExchanger = wctSupplyAt
        .add(wct1SupplyAt)
        .add(wct2SupplyAt)
        .mul(1250);
      const exchangerBalance = await wpr.balanceOf(exchanger.address);
      assert.equal(exchangerBalance.toNumber(), wprInExchanger.toNumber());
      let ownerBalance = await wpr.balanceOf(owner);
      assert.equal(ownerBalance.toNumber(), 0);
      await contribution.setBlockTimestamp(currentTime + 2);
      await exchanger.setBlockTimestamp(currentTime + 2);
      await contribution.sendTransaction({ from: owner });
      ownerBalance = await wpr.balanceOf(owner);
      assert.equal(ownerBalance.toNumber(), wprInExchanger.toNumber());

      await contribution.sendTransaction({
        from: miner,
        value: new BigNumber(10 ** 18)
      });

      let minerBalance = await wpr.balanceOf(miner);
      assert.equal(minerBalance.toNumber(), 1150 * 10 ** 18);
      assert.equal(
        (await contribution.totalCollected.call()).toNumber(),
        web3.toWei(1, "ether")
      );
    });
  });
});
