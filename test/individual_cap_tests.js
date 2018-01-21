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

contract("Individual Caps", ([miner, owner, investor, investor2, investor3]) => {
  let wpr;
  let contribution;
  let exchanger;
  let wct;
  let wct1;
  let wct2;
  let tokensPreSold = new BigNumber(50 ** 18 * 50);
  let totalCap;
  let sendingAmount;
  let currentTime;
  let futureHolder;
  let teamHolder;
  let _communityHolder;
  let latestBlockNumber;
  let num_investors;

  describe("#initialize", async function() {
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

      totalCap = web3.toWei(new BigNumber(10), 'ether'); //10 eth
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
      await contribution.whitelist(investor);
      await contribution.whitelist(investor2);
      await contribution.whitelist(investor3);
      num_investors = 4;
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
        currentTime + duration.days(1)
      );
    });

    it("During the first hour, the cap is split between each whitelisted investor", async function() {
      // Start time
      await contribution.setBlockTimestamp(currentTime + 1);

      // Total cap is 10 eth
      let value = web3.toWei(20, 'ether');
      await contribution.proxyPayment(investor, { from: investor, value: value });
      assert.equal((await wpr.balanceOf(investor)).toNumber(), (web3.toWei(new BigNumber(10000), 'ether')).toNumber());
    });

    it("During the first hour, the cap is split between each whitelisted investor, can't purchase additional tokens", async function() {
      // Start time
      await contribution.setBlockTimestamp(currentTime + 1);

      // Total cap is 10 eth
      let value = web3.toWei(20, 'ether');
      await contribution.proxyPayment(investor, { from: investor, value: value });
      assert.equal((await wpr.balanceOf(investor)).toNumber(), (web3.toWei(new BigNumber(10000), 'ether')).toNumber());
      await expectThrow(async () => {
        await contribution.proxyPayment(investor, { from: investor, value: value });
      });
      assert.equal((await wpr.balanceOf(investor)).toNumber(), (web3.toWei(new BigNumber(10000), 'ether')).toNumber());
    });

    it("After the first hour, a whitelisted investor can purchase the remaining tokens", async function() {
      await contribution.whitelist(investor);
      await contribution.whitelist(investor2);
      await contribution.whitelist(investor3);
      // (Miner is white listed too)

      // Start time + 1 hour
      await contribution.setBlockTimestamp(currentTime + 1 + duration.hours(2));

      // Total cap is 10 eth
      let value = web3.toWei(20, 'ether');
      assert.equal((await wpr.balanceOf(investor)).toNumber(), 0);
      await contribution.proxyPayment(investor, { from: investor, value: value });
      assert.equal((await wpr.balanceOf(investor)).toNumber(), (web3.toWei(new BigNumber(10000), 'ether')).toNumber());
    });
  });
});
