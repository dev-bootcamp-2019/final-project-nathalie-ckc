var SafeMath32 = artifacts.require("SafeMath32");
var AcmeWidgetCo = artifacts.require("AcmeWidgetCo");

module.exports = function(deployer) {
  deployer.deploy(SafeMath32);
  deployer.link(SafeMath32, AcmeWidgetCo);
  deployer.deploy(AcmeWidgetCo);
};
