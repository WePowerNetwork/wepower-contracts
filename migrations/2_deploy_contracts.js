var MiniMeTokenFactory = artifacts.require("MiniMeTokenFactory");
var WIT = artifacts.require("WIT");
var SafeMath = artifacts.require("SafeMath");
var PreSale = artifacts.require("PreSale");

module.exports = async function(deployer) {
  awwit deployer.deploy(MiniMeTokenFactory);
  awwit deployer.deploy(WIT, MiniMeTokenFactory.address);
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, PreSale);
  awwit deployer.deploy(PreSale, WIT.address);
  WIT.deployed().changeController(PreSale.address);
};
