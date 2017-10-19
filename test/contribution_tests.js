const MockContribution = artifacts.require("MockContribution.sol");
const WPR = artifacts.require("WPR.sol");
const WCT = artifacts.require("WCT.sol");
const WCT1 = artifacts.require("WCT1.sol");
const TeamTokenHolder = artifacts.require("TeamTokenHolder.sol");
const FutureTokenHolder = artifacts.require("FutureTokenHolder.sol");
const MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
const Exchanger = artifacts.require("Exchanger");
const assert = require("chai").assert;
const BigNumber = web3.BigNumber;
import { expectThrow, duration, latestBlock, getTime } from "./utils.js";

contract("Contribution", ([miner, owner, investor]) => {
  let wpr;
  let contribution;
  let exchanger;
  let wct;
  let wct1;
  let tokensPreSold = new BigNumber(10 ** 18 * 50);
  let bonusCap;
  let totalCap;
  let sendingAmount;
  let currentTime;
  let futureHolder;
  let teamHolder;
  let _communityHolder;
  let latestBlockNumber;
  let addresses = [
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501200",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501201",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501202",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501203",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501204",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501205",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501206",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501207",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501208",
    "0x2bdd21761a483f71054e14f5b827213567971c676928d9a1808cbfa4b7501209"
  ];

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
      wpr = await WPR.new();
      contribution = await MockContribution.new(wpr.address);
      exchanger = await Exchanger.new(
        wct.address,
        wct1.address,
        "0x0",
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
    });

    it("happy path", async function() {
      await wpr.transferOwnership(contribution.address);

      await contribution.initialize(
        wct.address,
        wct1.address,
        "0x0",
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
      assert.equal(
        exchangerBalance.toString(10),
        wctSupplyAt
          .add(wct1SupplyAt)
          .mul(1.15)
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
  });
});
