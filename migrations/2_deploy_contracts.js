var Adoption = artifacts.require("Adoption");
var AcmeWidgetCo = artifacts.require("AcmeWidgetCo");

module.exports = function(deployer) {
  deployer.deploy(Adoption);
  deployer.deploy(AcmeWidgetCo);
};
