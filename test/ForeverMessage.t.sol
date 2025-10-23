// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {ForeverMessage} from "../contracts/ForeverMessage.sol";

contract ForeverMessageTest is Test {
    ForeverMessage public foreverMessage;

    address public deployer;
    address public user1;
    address public user2;
    address public user3;

    string constant IPFS_HASH_1 = "QmTest1Hash123456789";
    string constant IPFS_HASH_2 = "QmTest2Hash987654321";
    string constant IPFS_HASH_COMMENT = "QmCommentHash111222333";

    event BottleCreated(
        uint256 indexed bottleId,
        address indexed creator,
        string ipfsHash,
        uint256 expiresAt
    );

    event BottleLiked(uint256 indexed bottleId, address indexed liker);
    event BottleUnliked(uint256 indexed bottleId, address indexed unliker);

    event CommentAdded(
        uint256 indexed commentId,
        uint256 indexed bottleId,
        address indexed commenter,
        string ipfsHash
    );

    event BottleMarkedForever(uint256 indexed bottleId);
    event BottleIPFSUpdated(uint256 indexed bottleId, string newIpfsHash);

    function setUp() public {
        deployer = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        foreverMessage = new ForeverMessage();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Deployment_Constants() public view {
        assertEq(foreverMessage.EXPIRATION_DAYS(), 30);
        assertEq(foreverMessage.SECONDS_PER_DAY(), 86400);
        assertEq(foreverMessage.FOREVER_LIKES_THRESHOLD(), 100);
        assertEq(foreverMessage.FOREVER_COMMENTS_THRESHOLD(), 4);
    }

    function test_Deployment_DeployerSet() public view {
        assertEq(foreverMessage.DEPLOYER(), deployer);
    }

    /*//////////////////////////////////////////////////////////////
                        CREATE BOTTLE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CreateBottle_Success() public {
        uint256 bottleId = foreverMessage.createBottle(IPFS_HASH_1, user1);

        (
            uint256 id,
            address creator,
            string memory ipfsHash,
            uint256 createdAt,
            uint256 expiresAt,
            bool isForever,
            bool exists
        ) = foreverMessage.bottles(bottleId);

        assertEq(id, 1);
        assertEq(creator, user1);
        assertEq(ipfsHash, IPFS_HASH_1);
        assertGt(createdAt, 0);
        assertEq(expiresAt, createdAt + (30 * 86400));
        assertFalse(isForever);
        assertTrue(exists);
    }

    function test_CreateBottle_EmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit BottleCreated(
            1,
            user1,
            IPFS_HASH_1,
            block.timestamp + (30 * 86400)
        );

        foreverMessage.createBottle(IPFS_HASH_1, user1);
    }

    function test_CreateBottle_MultipleUsers() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.createBottle(IPFS_HASH_2, user2);

        (, address creator1, , , , , ) = foreverMessage.bottles(1);
        (, address creator2, , , , , ) = foreverMessage.bottles(2);

        assertEq(creator1, user1);
        assertEq(creator2, user2);
    }

    function test_CreateBottle_RevertsIfEmptyHash() public {
        vm.expectRevert("IPFS hash cannot be empty");
        foreverMessage.createBottle("", user1);
    }

    function test_CreateBottle_RevertsIfInvalidCreator() public {
        vm.expectRevert("Invalid creator address");
        foreverMessage.createBottle(IPFS_HASH_1, address(0));
    }

    function test_CreateBottle_RevertsIfNotDeployer() public {
        vm.prank(user1);
        vm.expectRevert("Only deployer can call this function");
        foreverMessage.createBottle(IPFS_HASH_1, user1);
    }

    /*//////////////////////////////////////////////////////////////
                            LIKE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_LikeBottle_Success() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectEmit(true, true, false, false);
        emit BottleLiked(1, user2);

        foreverMessage.likeBottle(1, user2);
    }

    function test_LikeBottle_MultipleLikes() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        foreverMessage.likeBottle(1, user1);
        foreverMessage.likeBottle(1, user2);
        foreverMessage.likeBottle(1, user3);
        // All should succeed - no revert means success
    }

    function test_LikeBottle_RevertsIfInvalidLiker() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("Invalid liker address");
        foreverMessage.likeBottle(1, address(0));
    }

    function test_LikeBottle_RevertsIfExpired() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        // Fast forward 31 days
        vm.warp(block.timestamp + 31 days);

        vm.expectRevert("Bottle has expired");
        foreverMessage.likeBottle(1, user2);
    }

    function test_LikeBottle_RevertsIfNotDeployer() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.prank(user1);
        vm.expectRevert("Only deployer can call this function");
        foreverMessage.likeBottle(1, user2);
    }

    /*//////////////////////////////////////////////////////////////
                          UNLIKE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UnlikeBottle_Success() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectEmit(true, true, false, false);
        emit BottleUnliked(1, user2);

        foreverMessage.unlikeBottle(1, user2);
    }

    function test_UnlikeBottle_RevertsIfInvalidUnliker() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("Invalid unliker address");
        foreverMessage.unlikeBottle(1, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                          COMMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AddComment_Success() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        uint256 commentId = foreverMessage.addComment(
            1,
            IPFS_HASH_COMMENT,
            user2
        );

        (
            uint256 id,
            uint256 bottleId,
            address commenter,
            string memory ipfsHash,
            uint256 createdAt,
            bool exists
        ) = foreverMessage.comments(commentId);

        assertEq(id, 1);
        assertEq(bottleId, 1);
        assertEq(commenter, user2);
        assertEq(ipfsHash, IPFS_HASH_COMMENT);
        assertGt(createdAt, 0);
        assertTrue(exists);
    }

    function test_AddComment_EmitsEvent() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectEmit(true, true, true, true);
        emit CommentAdded(1, 1, user2, IPFS_HASH_COMMENT);

        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user2);
    }

    function test_AddComment_MultipleComments() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user1);
        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user2);
        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user3);

        uint256[] memory comments = foreverMessage.getBottleComments(1);
        assertEq(comments.length, 3);
    }

    function test_AddComment_RevertsIfEmptyHash() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("IPFS hash cannot be empty");
        foreverMessage.addComment(1, "", user2);
    }

    function test_AddComment_RevertsIfInvalidCommenter() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("Invalid commenter address");
        foreverMessage.addComment(1, IPFS_HASH_COMMENT, address(0));
    }

    function test_AddComment_RevertsIfBottleExpired() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.warp(block.timestamp + 31 days);

        vm.expectRevert("Bottle has expired");
        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user2);
    }

    /*//////////////////////////////////////////////////////////////
                    FOREVER PROMOTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CheckAndPromoteToForever_Success() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectEmit(true, false, false, false);
        emit BottleMarkedForever(1);

        foreverMessage.checkAndPromoteToForever(1, 100, 4);

        (, , , , , bool isForever, ) = foreverMessage.bottles(1);
        assertTrue(isForever);
    }

    function test_CheckAndPromoteToForever_ExactThresholds() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        // Exactly 100 likes and 4 comments should work
        foreverMessage.checkAndPromoteToForever(1, 100, 4);

        (, , , , , bool isForever, ) = foreverMessage.bottles(1);
        assertTrue(isForever);
    }

    function test_CheckAndPromoteToForever_AboveThresholds() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        // Way above thresholds should work
        foreverMessage.checkAndPromoteToForever(1, 500, 20);

        (, , , , , bool isForever, ) = foreverMessage.bottles(1);
        assertTrue(isForever);
    }

    function test_CheckAndPromoteToForever_RevertsIfLikesInsufficient() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("Thresholds not met");
        foreverMessage.checkAndPromoteToForever(1, 99, 4);
    }

    function test_CheckAndPromoteToForever_RevertsIfCommentsInsufficient()
        public
    {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("Thresholds not met");
        foreverMessage.checkAndPromoteToForever(1, 100, 3);
    }

    function test_CheckAndPromoteToForever_RevertsIfBothInsufficient() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("Thresholds not met");
        foreverMessage.checkAndPromoteToForever(1, 50, 2);
    }

    function test_CheckAndPromoteToForever_RevertsIfAlreadyForever() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.checkAndPromoteToForever(1, 100, 4);

        vm.expectRevert("Bottle is already forever");
        foreverMessage.checkAndPromoteToForever(1, 100, 4);
    }

    function test_ForeverBottle_DoesNotExpire() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.checkAndPromoteToForever(1, 100, 4);

        // Fast forward way past expiration
        vm.warp(block.timestamp + 365 days);

        // Should still be able to interact
        foreverMessage.likeBottle(1, user2);
        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user2);

        bool isExpired = foreverMessage.isBottleExpired(1);
        assertFalse(isExpired);
    }

    /*//////////////////////////////////////////////////////////////
                    MANUAL FOREVER MARKING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MarkBottleAsForever_Success() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectEmit(true, false, false, false);
        emit BottleMarkedForever(1);

        foreverMessage.markBottleAsForever(1);

        (, , , , , bool isForever, ) = foreverMessage.bottles(1);
        assertTrue(isForever);
    }

    function test_MarkBottleAsForever_RevertsIfAlreadyForever() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.markBottleAsForever(1);

        vm.expectRevert("Bottle is already forever");
        foreverMessage.markBottleAsForever(1);
    }

    /*//////////////////////////////////////////////////////////////
                        EXPIRATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_IsBottleExpired_NotExpiredInitially() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        bool isExpired = foreverMessage.isBottleExpired(1);
        assertFalse(isExpired);
    }

    function test_IsBottleExpired_NotExpiredBeforeDeadline() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        // 29 days later
        vm.warp(block.timestamp + 29 days);

        bool isExpired = foreverMessage.isBottleExpired(1);
        assertFalse(isExpired);
    }

    function test_IsBottleExpired_ExpiredAfterDeadline() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        // 31 days later
        vm.warp(block.timestamp + 31 days);

        bool isExpired = foreverMessage.isBottleExpired(1);
        assertTrue(isExpired);
    }

    function test_IsBottleExpired_ForeverNeverExpires() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.markBottleAsForever(1);

        // 1 year later
        vm.warp(block.timestamp + 365 days);

        bool isExpired = foreverMessage.isBottleExpired(1);
        assertFalse(isExpired);
    }

    /*//////////////////////////////////////////////////////////////
                        IPFS UPDATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UpdateBottleIPFS_Success() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectEmit(true, false, false, true);
        emit BottleIPFSUpdated(1, IPFS_HASH_2);

        foreverMessage.updateBottleIPFS(1, IPFS_HASH_2);

        (, , string memory ipfsHash, , , , ) = foreverMessage.bottles(1);
        assertEq(ipfsHash, IPFS_HASH_2);
    }

    function test_UpdateBottleIPFS_RevertsIfEmptyHash() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("IPFS hash cannot be empty");
        foreverMessage.updateBottleIPFS(1, "");
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_GetBottle_Success() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        ForeverMessage.Bottle memory bottle = foreverMessage.getBottle(1);

        assertEq(bottle.id, 1);
        assertEq(bottle.creator, user1);
        assertEq(bottle.ipfsHash, IPFS_HASH_1);
        assertGt(bottle.createdAt, 0);
        assertEq(bottle.expiresAt, bottle.createdAt + 30 days);
        assertFalse(bottle.isForever);
        assertTrue(bottle.exists);
    }

    function test_GetBottle_RevertsIfNotExists() public {
        vm.expectRevert("Bottle does not exist");
        foreverMessage.getBottle(999);
    }

    function test_GetBottleComments_EmptyInitially() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        uint256[] memory comments = foreverMessage.getBottleComments(1);
        assertEq(comments.length, 0);
    }

    function test_GetBottleComments_ReturnsAllComments() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);

        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user1);
        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user2);
        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user3);

        uint256[] memory comments = foreverMessage.getBottleComments(1);
        assertEq(comments.length, 3);
        assertEq(comments[0], 1);
        assertEq(comments[1], 2);
        assertEq(comments[2], 3);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_MultipleBottles_IndependentComments() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.createBottle(IPFS_HASH_2, user2);

        foreverMessage.addComment(1, IPFS_HASH_COMMENT, user1);
        foreverMessage.addComment(2, IPFS_HASH_COMMENT, user2);
        foreverMessage.addComment(2, IPFS_HASH_COMMENT, user3);

        uint256[] memory comments1 = foreverMessage.getBottleComments(1);
        uint256[] memory comments2 = foreverMessage.getBottleComments(2);

        assertEq(comments1.length, 1);
        assertEq(comments2.length, 2);
    }

    function test_SameUserMultipleBottles() public {
        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.createBottle(IPFS_HASH_2, user1);

        (, address creator1, , , , , ) = foreverMessage.bottles(1);
        (, address creator2, , , , , ) = foreverMessage.bottles(2);

        assertEq(creator1, user1);
        assertEq(creator2, user1);
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_CreateBottle_AnyValidAddress(address creator) public {
        vm.assume(creator != address(0));

        uint256 bottleId = foreverMessage.createBottle(IPFS_HASH_1, creator);

        (, address storedCreator, , , , , bool exists) = foreverMessage.bottles(
            bottleId
        );

        assertEq(storedCreator, creator);
        assertTrue(exists);
    }

    function testFuzz_CheckAndPromoteToForever_ValidCounts(
        uint256 likes,
        uint256 comments
    ) public {
        vm.assume(likes >= 100 && likes < type(uint256).max);
        vm.assume(comments >= 4 && comments < type(uint256).max);

        foreverMessage.createBottle(IPFS_HASH_1, user1);
        foreverMessage.checkAndPromoteToForever(1, likes, comments);

        (, , , , , bool isForever, ) = foreverMessage.bottles(1);
        assertTrue(isForever);
    }

    function testFuzz_CheckAndPromoteToForever_InvalidCounts(
        uint256 likes,
        uint256 comments
    ) public {
        vm.assume(likes < 100 || comments < 4);

        foreverMessage.createBottle(IPFS_HASH_1, user1);

        vm.expectRevert("Thresholds not met");
        foreverMessage.checkAndPromoteToForever(1, likes, comments);
    }
}
