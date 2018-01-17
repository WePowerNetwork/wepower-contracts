"use strict";

const InvestorWallet = artifacts.require("MockInvestorWallet.sol");
const InvestorWalletFactory = artifacts.require("InvestorWalletFactory.sol");
const WCT = artifacts.require("WCT.sol");
const WCT1 = artifacts.require("WCT1.sol");
const WCT2 = artifacts.require("WCT2.sol");
const WPR = artifacts.require("WPR.sol");
const Exchanger = artifacts.require("MockExchanger.sol");
const FutureTokenHolder = artifacts.require("FutureTokenHolder");
const TeamTokenHolder = artifacts.require("TeamTokenHolder");
const MockContribution = artifacts.require("MockContribution.sol");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const assert = require("chai").assert;
const BigNumber = web3.BigNumber;
import { expectThrow, duration, latestBlock, getTime } from "./utils.js";

contract("InvestorWallet", ([wePower, investor]) => {
  let investorWallet;
  let investorWalletFactory;
  let wct;
  let wct1;
  let wct2;
  let tokensPreSold = new BigNumber(50 * 10 ** 18);
  let wpr;
  let contribution;
  let exchanger;
  let walletFactory;
  let tokenFactory;
  let currentTime;
  let multiSig = wePower;
  let totalCap;
  let bonusCap;
  let collectorWeiCap;
  let futureHolder;
  let teamHolder;
  let _communityHolder;
  let latestBlockNumber;

  describe("#initialize", async function() {
    before(async function() {
      tokenFactory = await MiniMeTokenFactory.new();
    });

    beforeEach(async function() {
      wct = await WCT.new(tokenFactory.address);
      wct1 = await WCT1.new(tokenFactory.address);
      wct2 = await WCT2.new(tokenFactory.address);
      await wct.generateTokens(wePower, tokensPreSold);
      wpr = await WPR.new(tokenFactory.address);
      contribution = await MockContribution.new(wpr.address);
      exchanger = await Exchanger.new(
        wct.address,
        wct1.address,
        wct2.address,
        wpr.address,
        contribution.address
      );
      walletFactory = await InvestorWalletFactory.new(wct2.address);
      await wct2.changeController(walletFactory.address);

      futureHolder = await FutureTokenHolder.new(
        wePower,
        contribution.address,
        wpr.address
      );
      teamHolder = await TeamTokenHolder.new(
        wePower,
        contribution.address,
        wpr.address
      );
      _communityHolder = "0x0039F22efB07A647557C7C5d17854CFD6D489eF3";
      totalCap = new BigNumber(5 * 10 ** 18); // 5 eth
      bonusCap = totalCap.div(10);
      currentTime = getTime();
      latestBlockNumber = await latestBlock();

      await contribution.setBlockTimestamp(currentTime);
      await contribution.setBlockNumber(latestBlockNumber);
      await wpr.transferOwnership(contribution.address);
      await walletFactory.setExchanger(exchanger.address);

      await contribution.initialize(
        wct.address,
        wct1.address,
        wct2.address,
        exchanger.address,
        multiSig,
        futureHolder.address,
        teamHolder.address,
        _communityHolder,
        bonusCap,
        totalCap,
        currentTime + 1,
        currentTime + 10
      );
      currentTime = getTime();
      latestBlockNumber = await latestBlock();
      await contribution.setBlockTimestamp(currentTime + 2);
      await contribution.setBlockNumber(latestBlockNumber + 1);
    });

    it("factory mints and initiates wallet correctly", async function() {
      let transaction = await walletFactory.createInvestorWallet(
        5,
        investor,
        1000
      );

      investorWallet = InvestorWallet.at(transaction.receipt.logs[0].address);

      let investorBalance = await wct2.balanceOf(investorWallet.address);
      assert.equal(investorBalance.toNumber(), 1000);
      currentTime = await getTime();
      assert.equal(
        (await investorWallet.releaseTime()).toNumber(),
        currentTime + duration.months(5)
      );
    });

    it("let's the investor take the tokens after the period", async function() {
      investorWallet = await InvestorWallet.new(
        wct2.address,
        walletFactory.address,
        5
      );
      await investorWallet.transferOwnership(investor);
      await walletFactory.retrieveWCT2();
      wct2.generateTokens(investorWallet.address, 1000);
      wct2.changeController(walletFactory.address);
      currentTime = await getTime();
      await investorWallet.setBlockTimestamp(currentTime + duration.months(4));
      await exchanger.setBlockTimestamp(currentTime + duration.months(4));
      // await expectThrow(async () => {
      //   await investorWallet.collectTokens({ from: investor });
      // });
      await investorWallet.setBlockTimestamp(
        currentTime + duration.months(5) + duration.days(1)
      );
      await exchanger.setBlockTimestamp(
        currentTime + duration.months(5) + duration.days(1)
      );
      // await expectThrow(async () => {
      //   await investorWallet.collectTokens({ from: wePower });
      // });
      await investorWallet.collectTokens({ from: investor });
      investorBalance = await wct2.balanceOf(investor);
      assert.equal(investorBalance.toNumber(), 5 * 10 ** 18);
    });

    it("let's the investor take the tokens using an empty transaction", async function() {
      let investorWallet = await InvestorWallet.new(wct2.address, 5, {
        from: investor
      });
      currentTime = await getTime();
      await wct2.generateTokens(investorWallet.address, 5 * 10 ** 18);
      let investorBalance = await wct2.balanceOf(investor);
      assert.equal(investorBalance.toNumber(), 0);
      await investorWallet.setBlockTimestamp(
        currentTime + duration.months(5) + duration.days(1)
      );
      await investorWallet.sendTransaction({ from: investor });
      investorBalance = await wct2.balanceOf(investor);
      assert.equal(investorBalance.toNumber(), 5 * 10 ** 18);
    });
  });
});
