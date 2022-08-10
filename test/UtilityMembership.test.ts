import { expect } from 'chai';
import { ethers } from 'hardhat';
import { Contract, utils } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

describe('UtilityMembership', function () {
  let _: SignerWithAddress;
  let alice: SignerWithAddress;
  let membership: Contract;
  const price = utils.parseEther('0.1');
  const attributes = [0];

  before(async function () {
    [_, alice] = await ethers.getSigners();
    const UtilityMembershipFactory = await ethers.getContractFactory('UtilityMembership');
    membership = await UtilityMembershipFactory.deploy(price);
  });

  describe('#requestMembership', () => {
    it('should request membership properly first time', async () => {
      const tx = await membership.connect(alice).requestMembership(attributes, { value: price });
      expect(tx).emit(membership, 'UtilityCreated').withArgs(alice.address);
    });

    it('should revert if pending request exists', async () => {
      await expect(membership.connect(alice).requestMembership(attributes)).to.revertedWith(
        'Membership: pending request exists',
      );
    });

    it('should revert if membership already exists', async () => {
      await membership.approveRequest(alice.address);
      expect(await membership.isCurrentMember(alice.address)).to.eq(true);
      await expect(membership.connect(alice).requestMembership(attributes)).to.revertedWith(
        'Membership: already approved',
      );
    });
  });

  describe('#forfeitMembership', () => {
    it('should forfeit properly', async () => {
      await membership.connect(alice).forfeitMembership({ value: price });
      expect(await membership.isCurrentMember(alice.address)).to.eq(false);
      expect(await ethers.provider.getBalance(membership.address)).to.eq(price.mul(2));
    });

    it('should revert forfeit second time', async () => {
      await expect(membership.connect(alice).forfeitMembership({ value: price })).to.revertedWith(
        'Membership: nothing to forfeit',
      );
    });
  });
});
