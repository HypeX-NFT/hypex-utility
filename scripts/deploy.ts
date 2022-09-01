const { ethers, upgrades } = require('hardhat');

async function main() {
  const UtilityHelperFactory = await ethers.getContractFactory('UtilityHelper');
  const UtilityFactory = await ethers.getContractFactory('UtilityFactory');

  const helper = await UtilityHelperFactory.deploy();
  const factory = await upgrades.deployProxy(UtilityFactory, [helper.address], {
    initializer: 'initialize',
    kind: 'uups',
  });
  console.log(helper.address);
  console.log(factory.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
