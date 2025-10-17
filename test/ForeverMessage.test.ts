import { expect } from "chai";
import { network } from "hardhat";

describe("ForeverMessage", function () {
  const IPFS_HASH_1 = "QmTest1Hash123456789";
  const IPFS_HASH_2 = "QmTest2Hash987654321";
  const IPFS_HASH_COMMENT = "QmCommentHash111222333";

  async function deployFixture() {
    const { ethers, networkHelpers } = await network.connect();
    const [owner, user1, user2, user3] = await ethers.getSigners();
    const foreverMessage = await ethers.deployContract("ForeverMessage");
    return { foreverMessage, owner, user1, user2, user3, networkHelpers };
  }

  describe("Deployment", function () {
    it("Should set the correct constants", async function () {
      const { foreverMessage } = await deployFixture();
      expect(await foreverMessage.COMMENTS_THRESHOLD()).to.equal(4);
      expect(await foreverMessage.LIKES_THRESHOLD()).to.equal(100);
      expect(await foreverMessage.EXPIRATION_DAYS()).to.equal(30);
      expect(await foreverMessage.SECONDS_PER_DAY()).to.equal(86400);
    });
  });

  describe("Creating Bottles", function () {
    it("Should create a bottle with correct data", async function () {
      const { foreverMessage, user1 } = await deployFixture();
      await foreverMessage.connect(user1).createBottle(IPFS_HASH_1);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.id).to.equal(1);
      expect(bottle.author).to.equal(user1.address);
      expect(bottle.ipfsHash).to.equal(IPFS_HASH_1);
      expect(bottle.likeCount).to.equal(0);
      expect(bottle.commentCount).to.equal(0);
      expect(bottle.isForever).to.equal(false);
      expect(bottle.exists).to.equal(true);
    });

    it("Should revert if IPFS hash is empty", async function () {
      const { foreverMessage, user1 } = await deployFixture();
      await expect(foreverMessage.connect(user1).createBottle(""))
        .to.be.revertedWith("IPFS hash cannot be empty");
    });

    it("Should set expiration to 30 days from creation", async function () {
      const { foreverMessage, user1 } = await deployFixture();
      await foreverMessage.connect(user1).createBottle(IPFS_HASH_1);
      const bottle = await foreverMessage.getBottle(1);
      const expectedExpiration = bottle.createdAt + BigInt(30 * 86400);
      expect(bottle.expiresAt).to.equal(expectedExpiration);
    });
  });

  describe("Liking Bottles", function () {
    it("Should allow a user to like a bottle", async function () {
      const { foreverMessage, user1, user2 } = await deployFixture();
      await foreverMessage.connect(user1).createBottle(IPFS_HASH_1);
      await foreverMessage.connect(user2).likeBottle(1);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.likeCount).to.equal(1);
      const hasLiked = await foreverMessage.hasUserLikedBottle(1, user2.address);
      expect(hasLiked).to.equal(true);
    });

    it("Should revert if user tries to like twice", async function () {
      const { foreverMessage, user1, user2 } = await deployFixture();
      await foreverMessage.connect(user1).createBottle(IPFS_HASH_1);
      await foreverMessage.connect(user2).likeBottle(1);
      await expect(foreverMessage.connect(user2).likeBottle(1))
        .to.be.revertedWith("Already liked this bottle");
    });

    it("Should revert if bottle is expired", async function () {
      const { foreverMessage, user1, user2, networkHelpers } = await deployFixture();
      await foreverMessage.connect(user1).createBottle(IPFS_HASH_1);
      await networkHelpers.time.increase(31 * 24 * 60 * 60);
      await expect(foreverMessage.connect(user2).likeBottle(1))
        .to.be.revertedWith("Bottle has expired");
    });
  });

  describe("Adding Comments", function () {
    it("Should add a comment to a bottle", async function () {
      const { foreverMessage, user1, user2 } = await deployFixture();
      await foreverMessage.connect(user1).createBottle(IPFS_HASH_1);
      await foreverMessage.connect(user2).addComment(1, IPFS_HASH_COMMENT);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.commentCount).to.equal(1);
      const bottleComments = await foreverMessage.getBottleComments(1);
      expect(bottleComments.length).to.equal(1);
      expect(bottleComments[0]).to.equal(1);
    });

    it("Should revert if IPFS hash is empty", async function () {
      const { foreverMessage, user1, user2 } = await deployFixture();
      await foreverMessage.connect(user1).createBottle(IPFS_HASH_1);
      await expect(foreverMessage.connect(user2).addComment(1, ""))
        .to.be.revertedWith("IPFS hash cannot be empty");
    });
  });
});
