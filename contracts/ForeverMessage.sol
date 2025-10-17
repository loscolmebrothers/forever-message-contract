// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ForeverMessage {
    // Constants for permanence requirements
    uint256 public constant COMMENTS_THRESHOLD = 4;
    uint256 public constant LIKES_THRESHOLD = 100;
    uint256 public constant EXPIRATION_DAYS = 30;
    uint256 public constant SECONDS_PER_DAY = 86400;

    // Bottle structure representing a message
    struct Bottle {
        uint256 id;
        address author;
        string ipfsHash;
        uint256 createdAt;
        uint256 expiresAt;
        uint256 likeCount;
        uint256 commentCount;
        bool isForever;
        bool exists;
    }

    // Comment structure
    struct Comment {
        uint256 id;
        uint256 bottleId;
        address author;
        string ipfsHash;
        uint256 createdAt;
        bool exists;
    }

    // State variables
    uint256 private nextBottleId;
    uint256 private nextCommentId;

    // Mappings
    mapping(uint256 => Bottle) public bottles;
    mapping(uint256 => Comment) public comments;
    mapping(uint256 => uint256[]) public bottleComments;
    mapping(uint256 => mapping(address => bool)) public bottleLikes;
    mapping(address => uint256[]) public userBottles;

    // Events
    event BottleCreated(
        uint256 indexed bottleId,
        address indexed author,
        string ipfsHash,
        uint256 expiresAt
    );
    event BottleLiked(uint256 indexed bottleId, address indexed liker);
    event BottleUnliked(uint256 indexed bottleId, address indexed unliker);
    event CommentAdded(
        uint256 indexed commentId,
        uint256 indexed bottleId,
        address indexed author,
        string ipfsHash
    );
    event BottleBecameForever(uint256 indexed bottleId);

    // Modifiers
    modifier bottleExists(uint256 _bottleId) {
        require(bottles[_bottleId].exists, "Bottle does not exist");
        _;
    }

    modifier bottleNotExpired(uint256 _bottleId) {
        require(
            bottles[_bottleId].isForever ||
                block.timestamp < bottles[_bottleId].expiresAt,
            "Bottle has expired"
        );
        _;
    }

    constructor() {
        nextBottleId = 1;
        nextCommentId = 1;
    }

    // Create a new bottle (message)
    function createBottle(string memory _ipfsHash) external returns (uint256) {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        uint256 bottleId = nextBottleId++;
        uint256 expiresAt = block.timestamp +
            (EXPIRATION_DAYS * SECONDS_PER_DAY);

        bottles[bottleId] = Bottle({
            id: bottleId,
            author: msg.sender,
            ipfsHash: _ipfsHash,
            createdAt: block.timestamp,
            expiresAt: expiresAt,
            likeCount: 0,
            commentCount: 0,
            isForever: false,
            exists: true
        });

        userBottles[msg.sender].push(bottleId);

        emit BottleCreated(bottleId, msg.sender, _ipfsHash, expiresAt);

        return bottleId;
    }

    // Like a bottle
    function likeBottle(
        uint256 _bottleId
    ) external bottleExists(_bottleId) bottleNotExpired(_bottleId) {
        require(
            !bottleLikes[_bottleId][msg.sender],
            "Already liked this bottle"
        );

        bottleLikes[_bottleId][msg.sender] = true;
        bottles[_bottleId].likeCount++;

        emit BottleLiked(_bottleId, msg.sender);

        _checkForeverStatus(_bottleId);
    }

    // Unlike a bottle
    function unlikeBottle(
        uint256 _bottleId
    ) external bottleExists(_bottleId) bottleNotExpired(_bottleId) {
        require(
            bottleLikes[_bottleId][msg.sender],
            "Have not liked this bottle"
        );

        bottleLikes[_bottleId][msg.sender] = false;
        bottles[_bottleId].likeCount--;

        emit BottleUnliked(_bottleId, msg.sender);
    }

    // Add a comment to a bottle
    function addComment(
        uint256 _bottleId,
        string memory _ipfsHash
    )
        external
        bottleExists(_bottleId)
        bottleNotExpired(_bottleId)
        returns (uint256)
    {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        uint256 commentId = nextCommentId++;

        comments[commentId] = Comment({
            id: commentId,
            bottleId: _bottleId,
            author: msg.sender,
            ipfsHash: _ipfsHash,
            createdAt: block.timestamp,
            exists: true
        });

        bottleComments[_bottleId].push(commentId);
        bottles[_bottleId].commentCount++;

        emit CommentAdded(commentId, _bottleId, msg.sender, _ipfsHash);

        _checkForeverStatus(_bottleId);

        return commentId;
    }

    // Internal function to check if bottle should become permanent
    function _checkForeverStatus(uint256 _bottleId) private {
        Bottle storage bottle = bottles[_bottleId];

        if (
            !bottle.isForever &&
            bottle.likeCount >= LIKES_THRESHOLD &&
            bottle.commentCount >= COMMENTS_THRESHOLD
        ) {
            bottle.isForever = true;
            emit BottleBecameForever(_bottleId);
        }
    }

    // View functions
    function getBottle(
        uint256 _bottleId
    ) external view bottleExists(_bottleId) returns (Bottle memory) {
        return bottles[_bottleId];
    }

    function getBottleComments(
        uint256 _bottleId
    ) external view bottleExists(_bottleId) returns (uint256[] memory) {
        return bottleComments[_bottleId];
    }

    function getUserBottles(
        address _user
    ) external view returns (uint256[] memory) {
        return userBottles[_user];
    }

    function hasUserLikedBottle(
        uint256 _bottleId,
        address _user
    ) external view bottleExists(_bottleId) returns (bool) {
        return bottleLikes[_bottleId][_user];
    }

    function isBottleExpired(
        uint256 _bottleId
    ) external view bottleExists(_bottleId) returns (bool) {
        if (bottles[_bottleId].isForever) {
            return false;
        }
        return block.timestamp >= bottles[_bottleId].expiresAt;
    }
}
