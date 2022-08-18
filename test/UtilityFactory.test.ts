import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { Contract, constants } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

describe('UtilityFactory', function () {
  let _: SignerWithAddress;
  let alice: SignerWithAddress;
  let helper: Contract;
  let factory: Contract;
  let nft: Contract;
  let ownedNFT: Contract;

  beforeEach(async function () {
    [_, alice] = await ethers.getSigners();
    const UtilityHelperFactory = await ethers.getContractFactory('UtilityHelper');
    const UtilityFactory = await ethers.getContractFactory('UtilityFactory');
    const MockNFTFactory = await ethers.getContractFactory('MockNFT');
    const MockOwnedNFTFactory = await ethers.getContractFactory('MockOwnedNFT');

    helper = await UtilityHelperFactory.deploy();
    nft = await MockNFTFactory.deploy();
    ownedNFT = await MockOwnedNFTFactory.deploy();
    factory = await upgrades.deployProxy(UtilityFactory, [helper.address], {
      initializer: 'initialize',
      kind: 'uups',
    });
  });

  describe('#initialize', () => {
    it('revert if helper address is 0x0', async () => {
      const UtilityFactory = await ethers.getContractFactory('UtilityFactory');
      await expect(
        upgrades.deployProxy(UtilityFactory, [constants.AddressZero], {
          initializer: 'initialize',
          kind: 'uups',
        }),
      ).to.revertedWith('Factory: helper address is 0x0');
    });

    it('check helper address', async () => {
      expect(await factory.helper()).to.eq(helper.address);
    });
  });

  describe('#bind', () => {
    it('should bind owned nft properly', async () => {
      const tx = await factory.bind(ownedNFT.address, 0);
      const receipt = await tx.wait();
      const utility = receipt.events[0].args.utility;
      expect(tx).emit(factory, 'UtilityCreated').withArgs(ownedNFT.address, utility, 0);
      expect(await factory.utilities(ownedNFT.address)).to.eq(utility);
    });

    it('should revert if bind called by not owner', async () => {
      await expect(factory.connect(alice).bind(ownedNFT.address, 0)).to.revertedWith(
        'Factory: not nft issuer',
      );
    });

    it('should bind nft properly', async () => {
      const tx = await factory.bind(nft.address, 0);
      const receipt = await tx.wait();
      const utility = receipt.events[0].args.utility;
      expect(tx).emit(factory, 'UtilityCreated').withArgs(nft.address, utility, 0);
      expect(await factory.utilities(nft.address)).to.eq(utility);
    });
  });
});
