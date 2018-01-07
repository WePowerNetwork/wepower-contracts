const InvestorWallet = artifacts.require("MockInvestorWallet.sol");
const InvestorWalletFactory = artifacts.require("InvestorWalletFactory.sol");
const WCT2 = artifacts.require("WCT2.sol");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const assert = require("chai").assert;
const BigNumber = web3.BigNumber;
import { expectThrow, duration, latestBlock, getTime } from "./utils.js";

contract("InvestorWallet", ([wePower, investor]) => {
  let investorWallet;
  let investorWalletFactory;
  let wct2;
  let tokenFactory;
  let currentTime;

  describe("#initialize", async function() {
    before(async function() {
      tokenFactory = await MiniMeTokenFactory.new();
    });
    beforeEach(async function() {
      wct2 = await WCT2.new(tokenFactory.address);
    });

    it("let's the investor take the tokens after the period", async function() {
      let investorWallet = await InvestorWallet.new(wct2.address, 5, {
        from: investor
      });
      currentTime = await getTime();
      await wct2.generateTokens(investorWallet.address, 5 * 10 ** 18);
      let investorBalance = await wct2.balanceOf(investor);
      assert.equal(investorBalance.toNumber(), 0);
      await investorWallet.setBlockTimestamp(currentTime + duration.months(4));
      await expectThrow(investorWallet.collectTokens({ from: investor }));
      await investorWallet.setBlockTimestamp(
        currentTime + duration.months(5) + duration.days(1)
      );
      await expectThrow(investorWallet.collectTokens({ from: wePower }));
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
