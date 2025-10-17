import { expect } from "chai";
import hre from "hardhat";

describe("ForeverMessage", function () {
  const IPFS_HASH_1 = "QmTest1Hash123456789";
  const IPFS_HASH_2 = "QmTest2Hash987654321";
  const IPFS_HASH_COMMENT = "QmCommentHash111222333";

  let foreverMessage: any;
  let owner: any;
  let user1: any;
  let user2: any;
  let user3: any;

  beforeEach(async function () {
    const { ethers, networkHelpers } = await hre.network.connect();
    [owner, user1, user2, user3] = await ethers.getSigners();
    const ForeverMessage = await ethers.getContractFactory("ForeverMessage");
    foreverMessage = await ForeverMessage.deploy();
    this.time = networkHelpers.time;
  });

  describe("Deployment", function () {
    it("Should set the correct constants", async function () {
      expect(await foreverMessage.COMMENTS_THRESHOLD()).to.equal(4);
      expect(await foreverMessage.LIKES_THRESHOLD()).to.equal(100);
      expect(await foreverMessage.EXPIRATION_DAYS()).to.equal(30);
      expect(await foreverMessage.SECONDS_PER_DAY()).to.equal(86400);
    });

    it("Should set the deployer address", async function () {
      expect(await foreverMessage.DEPLOYER()).to.equal(owner.address);
    });
  });

  describe("Creating Bottles", function () {
    it("Should create a bottle with correct data", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.id).to.equal(1);
      expect(bottle.ipfsHash).to.equal(IPFS_HASH_1);
      expect(bottle.likeCount).to.equal(0);
      expect(bottle.commentCount).to.equal(0);
      expect(bottle.isForever).to.equal(false);
      expect(bottle.exists).to.equal(true);
    });

    it("Should revert if IPFS hash is empty", async function () {
      await expect(
        foreverMessage.connect(owner).createBottle("")
      ).to.be.revertedWith("IPFS hash cannot be empty");
    });

    it("Should set expiration to 30 days from creation", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      const bottle = await foreverMessage.getBottle(1);
      const expectedExpiration = bottle.createdAt + BigInt(30 * 86400);
      expect(bottle.expiresAt).to.equal(expectedExpiration);
    });

    it("Should revert if non-deployer tries to create a bottle", async function () {
      await expect(
        foreverMessage.connect(user1).createBottle(IPFS_HASH_1)
      ).to.be.revertedWith("Only deployer can call this function");
    });
  });

  describe("Liking Bottles", function () {
    it("Should allow deployer to like a bottle", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await foreverMessage.connect(owner).likeBottle(1);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.likeCount).to.equal(1);
    });

    it("Should increment like count multiple times", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await foreverMessage.connect(owner).likeBottle(1);
      await foreverMessage.connect(owner).likeBottle(1);
      await foreverMessage.connect(owner).likeBottle(1);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.likeCount).to.equal(3);
    });

    it("Should revert if bottle is expired", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await this.time.increase(31 * 24 * 60 * 60);
      await expect(
        foreverMessage.connect(owner).likeBottle(1)
      ).to.be.revertedWith("Bottle has expired");
    });

    it("Should revert if non-deployer tries to like", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await expect(
        foreverMessage.connect(user1).likeBottle(1)
      ).to.be.revertedWith("Only deployer can call this function");
    });
  });

  describe("Unliking Bottles", function () {
    it("Should allow deployer to unlike a bottle", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await foreverMessage.connect(owner).likeBottle(1);
      await foreverMessage.connect(owner).unlikeBottle(1);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.likeCount).to.equal(0);
    });
  });

  describe("Adding Comments", function () {
    it("Should add a comment to a bottle", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await foreverMessage.connect(owner).addComment(1, IPFS_HASH_COMMENT);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.commentCount).to.equal(1);
      const bottleComments = await foreverMessage.getBottleComments(1);
      expect(bottleComments.length).to.equal(1);
      expect(bottleComments[0]).to.equal(1);
    });

    it("Should revert if IPFS hash is empty", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await expect(
        foreverMessage.connect(owner).addComment(1, "")
      ).to.be.revertedWith("IPFS hash cannot be empty");
    });

    it("Should revert if non-deployer tries to add comment", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await expect(
        foreverMessage.connect(user1).addComment(1, IPFS_HASH_COMMENT)
      ).to.be.revertedWith("Only deployer can call this function");
    });
  });

  describe("Forever Status", function () {
    it("Should become forever when reaching thresholds", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);

      // Add 4 comments to reach COMMENTS_THRESHOLD
      for (let i = 0; i < 4; i++) {
        await foreverMessage
          .connect(owner)
          .addComment(1, `${IPFS_HASH_COMMENT}${i}`);
      }

      // Add 100 likes to reach LIKES_THRESHOLD
      for (let i = 0; i < 100; i++) {
        await foreverMessage.connect(owner).likeBottle(1);
      }

      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.isForever).to.equal(true);
    });

    it("Should not expire if bottle is forever", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);

      // Make bottle forever
      for (let i = 0; i < 4; i++) {
        await foreverMessage
          .connect(owner)
          .addComment(1, `${IPFS_HASH_COMMENT}${i}`);
      }
      for (let i = 0; i < 100; i++) {
        await foreverMessage.connect(owner).likeBottle(1);
      }

      // Advance time past expiration
      await this.time.increase(31 * 24 * 60 * 60);

      // Should still be able to interact with it
      await foreverMessage.connect(owner).likeBottle(1);
      const bottle = await foreverMessage.getBottle(1);
      expect(bottle.likeCount).to.equal(101);
    });
  });

  describe("Bottle Expiration", function () {
    it("Should report bottle as not expired before 30 days", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      const isExpired = await foreverMessage.isBottleExpired(1);
      expect(isExpired).to.equal(false);
    });

    it("Should report bottle as expired after 30 days", async function () {
      await foreverMessage.connect(owner).createBottle(IPFS_HASH_1);
      await this.time.increase(31 * 24 * 60 * 60);
      const isExpired = await foreverMessage.isBottleExpired(1);
      expect(isExpired).to.equal(true);
    });
  });
});
