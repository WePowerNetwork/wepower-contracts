const MockContribution = artifacts.require("MockContribution");
const WPR = artifacts.require("WPR");
const WCT1 = artifacts.require("WCT1");
const WCT2 = artifacts.require("WCT2");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const Exchanger = artifacts.require("MockExchanger");
const FutureTokenHolder = artifacts.require("FutureTokenHolder");
const TeamTokenHolder = artifacts.require("TeamTokenHolder");
const assert = require("chai").assert;
const BigNumber = web3.BigNumber;
import { expectThrow, duration, latestBlock, getTime } from "./utils.js";

contract(
  "Exchanger",
  ([miner, owner, dev, community, remainder, collector]) => {
    let tokenFactory;
    let wpr;
    let contribution;
    let exchanger;
    let wct1;
    let wct2;
    let tokensPreSold = new BigNumber(50 * 10 ** 18);
    let wprInExchanger = tokensPreSold.mul(1250);
    let multiSig = owner;
    let totalCap;
    let collectorWeiCap;
    let currentTime;
    let futureHolder;
    let teamHolder;
    let _communityHolder;
    let latestBlockNumber;

    describe("collect", async function() {
      before(async function() {
        tokenFactory = await MiniMeTokenFactory.new();
      });

      beforeEach(async function() {
        wct1 = await WCT1.new(tokenFactory.address);
        wct2 = await WCT2.new(tokenFactory.address);
        await wct1.generateTokens(owner, tokensPreSold);
        wpr = await WPR.new(tokenFactory.address);
        contribution = await MockContribution.new(wpr.address);
        exchanger = await Exchanger.new(
          wct1.address,
          wct2.address,
          wpr.address,
          contribution.address
        );

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

        totalCap = new BigNumber(5 * 10 ** 18); // 5 eth
        currentTime = getTime();

        latestBlockNumber = await latestBlock();

        await contribution.setBlockTimestamp(currentTime);
        await contribution.setBlockNumber(latestBlockNumber);
        await wpr.transferOwnership(contribution.address);

        await contribution.initialize(
          wct1.address,
          wct2.address,
          exchanger.address,
          multiSig,
          futureHolder.address,
          teamHolder.address,
          _communityHolder,
          totalCap,
          currentTime + 1,
          currentTime + 10
        );
        currentTime = getTime();
        latestBlockNumber = await latestBlock();
        await contribution.setBlockTimestamp(currentTime + 2);
        await contribution.setBlockNumber(latestBlockNumber + 1);
      });

      it("()", async function() {
        const exchangerBalance = await wpr.balanceOf.call(exchanger.address);
        assert.equal(exchangerBalance.toNumber(), wprInExchanger.toNumber());
        let ownerBalance = await wpr.balanceOf.call(owner);
        assert.equal(ownerBalance.toNumber(), 0);
        await exchanger.setBlockTimestamp(currentTime + 10);
        await exchanger.sendTransaction({ from: owner });
        ownerBalance = await wpr.balanceOf.call(owner);
        assert.equal(ownerBalance.toNumber(), wprInExchanger.toNumber());
      });

      it("() after contribution ends.", async function() {
        const exchangerBalance = await wpr.balanceOf.call(exchanger.address);
        assert.equal(exchangerBalance.toNumber(), wprInExchanger.toNumber());
        let ownerBalance = await wpr.balanceOf.call(owner);
        assert.equal(ownerBalance.toNumber(), 0);

        await contribution.setBlockTimestamp(currentTime + 10);

        await contribution.finalize();
        await wpr.unpause();

        await contribution.setBlockTimestamp(currentTime + 11);
        await exchanger.setBlockTimestamp(currentTime + 11);

        await exchanger.sendTransaction({ from: owner });
        ownerBalance = await wpr.balanceOf.call(owner);
        assert.equal(ownerBalance.toNumber(), wprInExchanger.toNumber());
      });

      it("empty transaction to contribution", async function() {
        const exchangerBalance = await wpr.balanceOf.call(exchanger.address);
        assert.equal(exchangerBalance.toNumber(), wprInExchanger.toNumber());
        let ownerBalance = await wpr.balanceOf.call(owner);
        assert.equal(ownerBalance.toNumber(), 0);
        await exchanger.setBlockTimestamp(currentTime + 10);
        await contribution.sendTransaction({ from: owner });
        ownerBalance = await wpr.balanceOf.call(owner);
        assert.equal(ownerBalance.toNumber(), wprInExchanger.toNumber());
      });
    });
  }
);
