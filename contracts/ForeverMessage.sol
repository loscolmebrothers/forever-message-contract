// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ForeverMessage {
    uint256 public constant EXPIRATION_DAYS = 30;
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant FOREVER_LIKES_THRESHOLD = 100;
    uint256 public constant FOREVER_COMMENTS_THRESHOLD = 4;

    address public immutable DEPLOYER;

    struct Bottle {
        uint256 id;
        address creator;
        string ipfsHash;
        uint256 createdAt;
        uint256 expiresAt;
        bool isForever;
        bool exists;
    }

    struct Comment {
        uint256 id;
        uint256 bottleId;
        address commenter;
        string ipfsHash;
        uint256 createdAt;
        bool exists;
    }

    uint256 private nextBottleId;
    uint256 private nextCommentId;

    mapping(uint256 => Bottle) public bottles;
    mapping(uint256 => Comment) public comments;
    mapping(uint256 => uint256[]) public bottleComments;

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

    modifier onlyDeployer() {
        require(msg.sender == DEPLOYER, "Only deployer can call this function");
        _;
    }

    constructor() {
        DEPLOYER = msg.sender;
        nextBottleId = 1;
        nextCommentId = 1;
    }

    function createBottle(
        string memory _ipfsHash,
        address _creator
    ) external onlyDeployer returns (uint256) {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(_creator != address(0), "Invalid creator address");

        uint256 bottleId = nextBottleId++;
        uint256 expiresAt = block.timestamp +
            (EXPIRATION_DAYS * SECONDS_PER_DAY);

        bottles[bottleId] = Bottle({
            id: bottleId,
            creator: _creator,
            ipfsHash: _ipfsHash,
            createdAt: block.timestamp,
            expiresAt: expiresAt,
            isForever: false,
            exists: true
        });

        emit BottleCreated(bottleId, _creator, _ipfsHash, expiresAt);

        return bottleId;
    }

    function likeBottle(
        uint256 _bottleId,
        address _liker
    )
        external
        onlyDeployer
        bottleExists(_bottleId)
        bottleNotExpired(_bottleId)
    {
        require(_liker != address(0), "Invalid liker address");
        emit BottleLiked(_bottleId, _liker);
    }

    function unlikeBottle(
        uint256 _bottleId,
        address _unliker
    )
        external
        onlyDeployer
        bottleExists(_bottleId)
        bottleNotExpired(_bottleId)
    {
        require(_unliker != address(0), "Invalid unliker address");
        emit BottleUnliked(_bottleId, _unliker);
    }

    function addComment(
        uint256 _bottleId,
        string memory _ipfsHash,
        address _commenter
    )
        external
        onlyDeployer
        bottleExists(_bottleId)
        bottleNotExpired(_bottleId)
        returns (uint256)
    {
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");
        require(_commenter != address(0), "Invalid commenter address");

        uint256 commentId = nextCommentId++;

        comments[commentId] = Comment({
            id: commentId,
            bottleId: _bottleId,
            commenter: _commenter,
            ipfsHash: _ipfsHash,
            createdAt: block.timestamp,
            exists: true
        });

        bottleComments[_bottleId].push(commentId);

        emit CommentAdded(commentId, _bottleId, _commenter, _ipfsHash);

        return commentId;
    }

    function updateBottleIPFS(
        uint256 _bottleId,
        string memory _newIpfsHash
    ) external onlyDeployer bottleExists(_bottleId) {
        require(bytes(_newIpfsHash).length > 0, "IPFS hash cannot be empty");
        bottles[_bottleId].ipfsHash = _newIpfsHash;
        emit BottleIPFSUpdated(_bottleId, _newIpfsHash);
    }

    function markBottleAsForever(
        uint256 _bottleId
    ) external onlyDeployer bottleExists(_bottleId) {
        require(!bottles[_bottleId].isForever, "Bottle is already forever");
        bottles[_bottleId].isForever = true;
        emit BottleMarkedForever(_bottleId);
    }

    function checkAndPromoteToForever(
        uint256 _bottleId,
        uint256 _likeCount,
        uint256 _commentCount
    ) external onlyDeployer bottleExists(_bottleId) {
        require(!bottles[_bottleId].isForever, "Bottle is already forever");
        require(
            _likeCount >= FOREVER_LIKES_THRESHOLD &&
                _commentCount >= FOREVER_COMMENTS_THRESHOLD,
            "Thresholds not met"
        );

        bottles[_bottleId].isForever = true;
        emit BottleMarkedForever(_bottleId);
    }

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

    function isBottleExpired(
        uint256 _bottleId
    ) external view bottleExists(_bottleId) returns (bool) {
        if (bottles[_bottleId].isForever) {
            return false;
        }
        return block.timestamp >= bottles[_bottleId].expiresAt;
    }
}
