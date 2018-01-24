require("babel-register");
require("babel-polyfill");

module.exports = {
  copyPackages: ["zeppelin-solidity"],
  skipFiles: ["ERC20.sol", "MiniMeToken.sol", "SafeMath.sol", "WCT.sol"],
  norpc: true
};
