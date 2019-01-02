pragma solidity ^0.4.24;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/AcmeWidgetCo.sol";

contract TestAcmeWidgetCo {
  // The address of the ACME Widget Company contract to be tested
  AcmeWidgetCo acme = AcmeWidgetCo(DeployedAddresses.AcmeWidgetCo());

  //  The id of the pet that will be used for testing
  uint expectedPetId = 8;

  // The expected owner of adopted pet is this contract
  address expectedAdopter = this;

  // Testing that the contract which deployed AcmeWidgetCo is an admin
  function testDeployerIsAdmin() public {
      bool isInList = acme.adminList[this];
      Assert.isTrue(isInList, "Test Contract is not an admin of AcmeWidgetCo.");
  }

  /*
  // Testing the that new users can be registered
  function testRegisteringNewUsers() public {
    bool isInList;

    isInList
    Assert.isTrue(returnedId, expectedPetId, "Adoption of the expected pet should match what is returned.");
  }

  // Testing retrieval of a single pet's owner
  function testGetAdopterAddressByPetId() public {
    address adopter = adoption.adopters(expectedPetId);
    Assert.equal(adopter, expectedAdopter, "Owner of the expected pet should be this contract");
  }

  // Testing retrieval of all pet owners
  function testGetAdopterAddressByPetIdInArray() public {
    // Store adopters in memory rather than contract's storage
    address[16] memory adopters = adoption.getAdopters();
    Assert.equal(adopters[expectedPetId], expectedAdopter, "Owner of the expected pet should be this contract");
  }
  */
}
