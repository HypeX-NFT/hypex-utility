import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { Contract, Wallet, constants } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

describe('UtilityFactory', function () {
  let _: SignerWithAddress;
  let alice: SignerWithAddress;
  let factory: Contract;
  let nft: Contract;
  let ownedNFT: Contract;

  beforeEach(async function () {
    [_, alice] = await ethers.getSigners();
    const UtilityFactory = await ethers.getContractFactory('UtilityFactory');
    const MockNFTFactory = await ethers.getContractFactory('MockNFT');
    const MockOwnedNFTFactory = await ethers.getContractFactory('MockOwnedNFT');

    factory = await UtilityFactory.deploy();
    nft = await MockNFTFactory.deploy();
    ownedNFT = await MockOwnedNFTFactory.deploy();
    factory = await upgrades.deployProxy(UtilityFactory, [], {
      initializer: 'initialize',
      kind: 'uups',
    });
  });

  describe('#bind', () => {
    it('should bind owned nft properly', async () => {
      const tx = await factory.bind(ownedNFT.address, true);
      const receipt = await tx.wait();
      const utility = receipt.events[0].args.utility;
      expect(tx).emit(factory, 'UtilityCreated').withArgs(ownedNFT.address, utility, true);
      expect(await factory.utilities(ownedNFT.address)).to.equal(utility);
    });

    it('should revert if bind called by not owner', async () => {
      await expect(factory.connect(alice).bind(ownedNFT.address, true)).to.revertedWith(
        'Factory: not nft issuer',
      );
    });

    it('should bind nft properly', async () => {
      const tx = await factory.bind(nft.address, true);
      const receipt = await tx.wait();
      const utility = receipt.events[0].args.utility;
      expect(tx).emit(factory, 'UtilityCreated').withArgs(nft.address, utility, true);
      expect(await factory.utilities(nft.address)).to.equal(utility);
    });
  });
});
