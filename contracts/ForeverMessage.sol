// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract ForeverMessage {
    uint256 public constant EXPIRATION_DAYS = 30;
    uint256 public constant SECONDS_PER_DAY = 86400;
    uint256 public constant FOREVER_LIKES_THRESHOLD = 100;

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

    uint256 public nextBottleId;

    mapping(uint256 => Bottle) public bottles;

    event BottleCreated(
        uint256 indexed bottleId,
        address indexed creator,
        string ipfsHash,
        uint256 expiresAt
    );
    event BottleLiked(uint256 indexed bottleId, address indexed liker);
    event BottleUnliked(uint256 indexed bottleId, address indexed unliker);
    event BottleMarkedForever(uint256 indexed bottleId);
    event BottleIPFSUpdated(uint256 indexed bottleId, string newIpfsHash);

    modifier bottleExists(uint256 _bottleId) {
        _bottleExists(_bottleId);
        _;
    }

    modifier bottleNotExpired(uint256 _bottleId) {
        _bottleNotExpired(_bottleId);
        _;
    }

    modifier onlyDeployer() {
        _onlyDeployer();
        _;
    }

    constructor() {
        DEPLOYER = msg.sender;
        nextBottleId = 1;
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

    function updateBottleIPFS(
        uint256 _bottleId,
        string memory _newIpfsHash
    ) external onlyDeployer bottleExists(_bottleId) {
        require(bytes(_newIpfsHash).length > 0, "IPFS hash cannot be empty");
        bottles[_bottleId].ipfsHash = _newIpfsHash;
        emit BottleIPFSUpdated(_bottleId, _newIpfsHash);
    }

    function checkIsForever(
        uint256 _bottleId,
        uint256 _likeCount
    ) external onlyDeployer bottleExists(_bottleId) {
        if (_meetsForeverThresholds(_likeCount)) {
            _promoteToForever(_bottleId);
        }
    }

    function _meetsForeverThresholds(
        uint256 _likeCount
    ) internal pure returns (bool) {
        return _likeCount >= FOREVER_LIKES_THRESHOLD;
    }

    function _promoteToForever(uint256 _bottleId) internal {
        if (bottles[_bottleId].isForever) {
            return;
        }
        bottles[_bottleId].isForever = true;
        emit BottleMarkedForever(_bottleId);
    }

    function _bottleExists(uint256 _bottleId) internal view {
        require(bottles[_bottleId].exists, "Bottle does not exist");
    }

    function _bottleNotExpired(uint256 _bottleId) internal view {
        require(
            bottles[_bottleId].isForever ||
                block.timestamp < bottles[_bottleId].expiresAt,
            "Bottle has expired"
        );
    }

    function _onlyDeployer() internal view {
        require(msg.sender == DEPLOYER, "Only deployer can call this function");
    }

    function getBottle(
        uint256 _bottleId
    ) external view bottleExists(_bottleId) returns (Bottle memory) {
        return bottles[_bottleId];
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
