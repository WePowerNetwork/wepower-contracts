var SafeMath = artifacts.require("SafeMath");
var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var WCT2 = artifacts.require("WCT2");
var InvestorWalletFactory = artifacts.require("InvestorWalletFactory");
var WCT1 = artifacts.require("WCT1");
var WPR = artifacts.require("WPR");
var Contribution = artifacts.require("Contribution");
var Exchanger = artifacts.require("Exchanger");
var TeamTokenHolder = artifacts.require("TeamTokenHolder");
var FutureTokenHolder = artifacts.require("FutureTokenHolder");

/*/var dateStart = Math.floor(new Date().getTime()/1000); // starts in 5 days
console.log(dateStart);
var dateEnd = dateStart + 10*24*60*60; // lasts 10 days
var owner = "0x0019810eAceA494E393daf6D2340092b89c97eBB";
/*/
module.exports = function(deployer) {
  return deployer.then(function(){
    // deploy SafeMath
   return deployer.deploy(SafeMath);
  }).then(function() {
    // link SafeMath
  return deployer.link(SafeMath, [Contribution, Exchanger, FutureTokenHolder, InvestorWalletFactory, TeamTokenHolder, WPR]);
  }).then(function(){
    // deploy MiniMeTokenFactory first
    return deployer.deploy(MiniMeTokenFactory);
  }).then(function(){
    // then WCT2
    return deployer.deploy(WCT2, MiniMeTokenFactory.address);
  }).then(function(){
    // then InvestorWalletFactory
    return deployer.deploy(InvestorWalletFactory, WCT2.address);
  }).then(function(){
    // then WCT1
    return deployer.deploy(WCT1, MiniMeTokenFactory.address);
  }).then(function(){
    // then WPR
    return deployer.deploy(WPR);
  }).then(function(){
    // then Contribution
    return deployer.deploy(Contribution, WPR.address);
  }).then(function(){
    // then Exchanger
    return deployer.deploy(Exchanger, WCT1.address, WCT2.address, WPR.address, Contribution.address);
  }).then(function(){
    // then TeamTokenHolder
    return deployer.deploy(TeamTokenHolder, deployer, Contribution.address, WPR.address);
  }).then(function(){
    // then FutureTokenHolder
    return deployer.deploy(FutureTokenHolder, deployer, Contribution.address, WPR.address);
  });
};
