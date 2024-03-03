// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "openzeppelin/access/Ownable.sol";
import "openzeppelin/token/ERC721/ERC721.sol";

/**
 * @title NFTMaestry
 * @dev This contract implements a simple ERC721 token with additional
 * functionalities for managing NFT mastery levels.
 */
contract NFTMaestry is ERC721, Ownable {
    ///////////////////////////////////////////////////////////
    ///                     EVENTS                          ///
    ///////////////////////////////////////////////////////////

    event NFTMaestryMinted(address indexed user, uint256 tokenId);
    event UpgradedLevel(address indexed user, Levels level);
    event UserAddedList(address user);

    ///////////////////////////////////////////////////////////
    ///                     ERRORS                          ///
    ///////////////////////////////////////////////////////////

    error NoHaveNFTMaestry();
    error YouAlreadyHaveNFTMaestry();
    error YouAreNotInList();

    ///////////////////////////////////////////////////////////
    ///                     STORAGE                         ///
    ///////////////////////////////////////////////////////////

    /**
     * @dev Enumeration defining the levels of the NFT.
     */
    enum Levels {
        BRONZE,
        SILVER,
        GOLD
    }

    /// @dev Struct representing the data associated with each NFT,
    /// including the owner's address and the level.
    struct Data {
        Levels level; // Level of the NFT
    }

    /// @dev Counter to keep track of the total number of NFTs minted.
    uint256 public counter;
    /// @dev Mapping to store the data associated with each NFT token ID.
    mapping(uint256 tokenId => Data) public maestryLevels;
    /// @dev Mapping to store the token ID associated with each user's address.
    mapping(address user => uint256 tokenId) public userTokenId;
    /// @dev Mapping to store whether a user is on the whitelist or not.
    mapping(address user => bool accepted) public whiteList;

    ///////////////////////////////////////////////////////////
    ///                    CONSTRUCTOR                      ///
    ///////////////////////////////////////////////////////////

    /**
     * @dev Constructor function to initialize the NFTMaestry contract.
     *      It sets the name and symbol for the ERC721 token and sets the deployer as the initial owner.
     */
    constructor() ERC721("NFTMaestry", "MST") Ownable(msg.sender) {}

    ///////////////////////////////////////////////////////////
    ///                USER FACING FUNCTIONS                ///
    ///////////////////////////////////////////////////////////

    /**
     * @notice This function mints NFTs NFTMaestry.
     * @dev Mint a new NFT and assign it to the caller.
     * Only users on the whitelist who do not already own an NFT can call this function.
     * The newly minted NFT is initialized as BRONZE.
     * Emits an NFTMaestryMinted event upon successful minting.
     */
    function mint() external {
        if (!whiteList[msg.sender]) revert YouAreNotInList();
        if (balanceOf(msg.sender) > 0) revert YouAlreadyHaveNFTMaestry();

        uint256 tokenId = counter;
        Levels bronze = Levels.BRONZE;

        Data storage data = maestryLevels[tokenId];
        data.level = bronze;
        userTokenId[msg.sender] = tokenId;

        _safeMint(msg.sender, tokenId);

        unchecked {
            counter = tokenId + 1;
        }
        emit NFTMaestryMinted(msg.sender, tokenId);
    }

    /**
     * @notice This function allows a user to upgrade the level of their NFT
     * from BRONZE to SILVER or from SILVER to GOLD.
     * Only users who own an NFT are allowed to upgrade its level.
     * @dev If the user already has a gold level, the function does nothing.
     * Emits an UpgradedLevel event upon successful upgrading.
     */
    function upGradeNft() external {
        if (balanceOf(msg.sender) == 0) revert NoHaveNFTMaestry();
        uint256 tokenId = userTokenId[msg.sender];

        Levels bronze = Levels.BRONZE;
        Levels silver = Levels.SILVER;
        Levels gold = Levels.GOLD;

        Data memory data = maestryLevels[tokenId];
        if (data.level == bronze) {
            data.level = silver;
            maestryLevels[tokenId] = data;

            emit UpgradedLevel(msg.sender, silver);
        } else if (data.level == silver) {
            data.level = gold;
            maestryLevels[tokenId] = data;

            emit UpgradedLevel(msg.sender, gold);
        } else {
            // If the level is gold, the function does nothing.
        }
    }

    ///////////////////////////////////////////////////////////
    ///          FUNCTIONS ONLY FOR THE OWNER                ///
    ///////////////////////////////////////////////////////////

    /**
     * @notice This function enables the contract owner to add a new address to the whitelist.
     * Only the contract owner has the authority to add addresses to the whitelist.
     * Emits an UpgradedLevel event upon successful adding.
     */
    function addWhiteList(address _user) external onlyOwner {
        whiteList[_user] = true;
        emit UserAddedList(_user);
    }

    /**
     * @notice Transfer an NFT from one address to another.
     * Only the contract owner can initiate this transfer.
     * @param from The address from which the NFT is being transferred.
     * @param to The address to which the NFT is being transferred.
     * @param tokenId The ID of the NFT being transferred.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyOwner {
        super.transferFrom(from, to, tokenId);
    }
}
