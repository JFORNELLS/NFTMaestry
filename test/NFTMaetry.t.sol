// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {NFTMaestry} from "../src/NFTMaestry.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract NFTMaestryTest is Test {

    ///////////////////////////////////////////////////////////
    ///                     EVENTS                          ///
    ///////////////////////////////////////////////////////////

    event NFTMaestryMinted(address indexed user, uint256 tokenId);
    event UpgradedLevel(address indexed user, NFTMaestry.Levels level);

    ///////////////////////////////////////////////////////////
    ///                     STORAGE                         ///
    ///////////////////////////////////////////////////////////

    enum Levels {
        BRONZE,
        SILVER,
        GOLD
    }

    struct Data {
        address owner;
        Levels level;
    }

    address public alice;
    address public bob;
    address public owner;
    NFTMaestry public nftMaestry;

    mapping(uint256 tokenId => Data) public maestryLevelsTest;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        owner = makeAddr("owner");

        vm.prank(owner);
        nftMaestry = new NFTMaestry();
    }

    function test_Mint() public {
        // Records the counter value before minting.
        uint256 beforeCounter = nftMaestry.counter();

        // Alice attempts to mint an NFT without being on the whitelist, which should revert.
        vm.prank(alice);
        vm.expectRevert(NFTMaestry.YouAreNotInList.selector);
        nftMaestry.mint();

        // Alice is added to the whitelist by the contract owner.
        vm.prank(owner);
        nftMaestry.addWhiteList(alice);
        vm.startPrank(alice);

        // This line verifies that the NFTMaestryMinted event is emitted correctly with Alice's address and token ID 0.
        vm.expectEmit();
        emit NFTMaestryMinted(alice, 0);

        // Alice mints a BRONZE level NFT.
        nftMaestry.mint();

        // If Alice tries to mint another NFT, the function will revert.
        vm.expectRevert(NFTMaestry.YouAlreadyHaveNFTMaestry.selector);
        nftMaestry.mint();

        // Records the counter value after minting.
        uint256 afterCounter = nftMaestry.counter();

        // Verify that the token counter has increased correctly.
        assertEq(afterCounter, beforeCounter +1);

        //Verify that the NFT minted by Alice has the BRONZE level.
        (NFTMaestry.Levels _level) = nftMaestry.maestryLevels(0);
        uint256 level = uint256(_level);
        uint256 levelTest = uint256(Levels.BRONZE);
        assertEq(levelTest, level);
        
    }

    function test_UpgradeNft() public {
        // Add Alice to the whitelist.
        vm.prank(owner);
        nftMaestry.addWhiteList(alice);

        vm.startPrank(alice);
        // Attempt to upgrade Alice's NFT when she doesn't have any, the function should revert.
        vm.expectRevert(NFTMaestry.NoHaveNFTMaestry.selector);
        nftMaestry.upGradeNft();

        // Alice mints an Nft..
        nftMaestry.mint();

        // Define variables to represent the numeric values of the SILVER and GOLD levels.
        uint256 bronze = uint256(Levels.BRONZE);
        uint256 silver = uint256(Levels.SILVER);
        uint256 gold = uint256(Levels.GOLD);

        // Recupera el nivel del NFT acuñado para la nueva dirección y verifica que esté en el nivel BRONCE.
        (NFTMaestry.Levels _level) = nftMaestry.maestryLevels(0);
        uint256 level = uint256(_level);
        assertEq(bronze, level);

        // Upgrade Alice's NFT to SILVER level and verify the upgrade event
        vm.expectEmit();
        emit UpgradedLevel(alice, NFTMaestry.Levels.SILVER);
        nftMaestry.upGradeNft();

        // Verify that Alice's NFT is now at SILVER level.
        (NFTMaestry.Levels _levelSilver) = nftMaestry.maestryLevels(0);
        uint256 levelSilver = uint256(_levelSilver);
        assertEq(silver, levelSilver);

        // Upgrade Alice's NFT to GOLD level and verify the upgrade event.
        vm.expectEmit();
        emit UpgradedLevel(alice, NFTMaestry.Levels.GOLD);
        nftMaestry.upGradeNft();

        // Verify that Alice's NFT is now at GOLD level.
        (NFTMaestry.Levels _levelGold) = nftMaestry.maestryLevels(0);
        uint256 levelGold = uint256(_levelGold);      
        assertEq(gold, levelGold);  

        // Attempt to upgrade Alice's NFT again, which should not change its level.
        nftMaestry.upGradeNft();
        (NFTMaestry.Levels _levelGold1) = nftMaestry.maestryLevels(0);
        uint256 levelGold1 = uint256(_levelGold1);      
        assertEq(gold, levelGold1);        
    }

    function test_AddWhiteList() public {
        // Alice's attempt to add herself to the whitelist will revert.
        vm.prank(alice);
        vm.expectRevert();
        nftMaestry.addWhiteList(alice);

        // Adding Alice to the whitelist by the owner.
        vm.prank(owner);
        nftMaestry.addWhiteList(alice);
        (bool added) = nftMaestry.whiteList(alice);
        assertTrue(added);
    }

    function test_TransferFrom()  public {
        //Add Alice and Owner to the whitelist and mint NFTs for each.
        vm.startPrank(owner);
        nftMaestry.addWhiteList(alice);
        nftMaestry.addWhiteList(owner);
        vm.stopPrank();

        // Alice mints an NFT.
        vm.startPrank(alice);
        nftMaestry.mint();

        // Attempt to transfer Alice's NFT to Bob using `transferFrom`, which should revert.
        vm.expectRevert();
        nftMaestry.transferFrom(alice, bob, 0);

        // Attempt to transfer Alice's NFT to Bob using `safeTransferFrom`, which should revert.
        vm.expectRevert();
        nftMaestry.safeTransferFrom(alice, bob, 0);

        vm.stopPrank();

        // Owner mints an NFT.
        vm.startPrank(owner);
        nftMaestry.mint();

        // Transfer Owner's NFT to Bob using `transferFrom'.
        nftMaestry.transferFrom(owner, bob, 1);

        // Owner mints another NFT.
        nftMaestry.mint();

        // ransfer Owner's NFT to Bob using `safeTransferFrom'.
        nftMaestry.safeTransferFrom(owner, bob, 2);
    }

    /**
     * @dev Executes a loop to perform fuzz testing by minting NFTs for randomly generated addresses.
     */
    function test_FuzzMint() public  {
        // Generates a random address.
        for(uint256 i; i < 1000; i++) {
            uint256 randomValue = uint256(keccak256(abi.encodePacked(39365 days + i)));
            address newAddress = address(uint160(randomValue % 1000000 ether * 600000));

            // Random Addresses attempt to mint an NFT without being on the whitelist, which should revert.
            vm.prank(newAddress);
            vm.expectRevert(NFTMaestry.YouAreNotInList.selector);
            nftMaestry.mint();

            // Adds the new address to the whitelist.
            vm.prank(owner);
            nftMaestry.addWhiteList(newAddress);

            // Records the counter value before minting.
            uint256 beforeCounter = nftMaestry.counter();

            // Expects that an NFTMaestryMinted event is emitted when minting an NFT 
            // for a newly generated address (newAddress) with a specific token ID (i).
            vm.expectEmit();
            emit NFTMaestryMinted(newAddress, i);            

            // Mint an NFT for the new address.
            vm.prank(newAddress);
            nftMaestry.mint();            

            // Records the counter value after minting.
            uint256 afterCounter = nftMaestry.counter();

            // Verifies that the counter has increased by one.
            assertEq(afterCounter, beforeCounter +1);

            // Retrieves the level of the NFT minted for the new address.
            (NFTMaestry.Levels _level) = nftMaestry.maestryLevels(i);
            uint256 level = uint256(_level);
            uint256 levelTest = uint256(Levels.BRONZE);

            // Verifies that the NFT with the correct level.
            assertEq(levelTest, level);            
          
        }         
    }

    /**
     * @dev Executes a loop to perform fuzz-testing by upgrading NFTs' for randomly generated addresses.
     */    
    function test_FuzzUpgradeNft() public { 
        // Generates a random address.
        for(uint256 i; i < 1000; i++) {
            uint256 randomValue = uint256(keccak256(abi.encodePacked(39365 days + i)));
            address newAddress = address(uint160(randomValue % 1000000));

            // New address attempting to upgrade an NFT without owning any, which will revert.
            vm.startPrank(newAddress);
            vm.expectRevert(NFTMaestry.NoHaveNFTMaestry.selector);
            nftMaestry.upGradeNft();
            vm.stopPrank();

            // Owner adds NnewAddress.
            vm.prank(owner);
            nftMaestry.addWhiteList(newAddress);

            // New Address mints an NFT.
            vm.startPrank(newAddress);
            nftMaestry.mint();

            // Define variables to represent the numeric values of the SILVER and GOLD levels.
            uint256 bronze = uint256(Levels.BRONZE);
            uint256 silver = uint256(Levels.SILVER);
            uint256 gold = uint256(Levels.GOLD);

            // Retrieve the level of the minted NFT for the new address and verify that it is at the BRONZE level.
            (NFTMaestry.Levels _level) = nftMaestry.maestryLevels(i);
            uint256 level = uint256(_level);
            assertEq(bronze, level); 

            // Upgrade newAddress's NFT to SILVER level and verify the upgrade event
            vm.expectEmit();
            emit UpgradedLevel(newAddress, NFTMaestry.Levels.SILVER);
            nftMaestry.upGradeNft();                 

            
            // Verify that newAddress's NFT is now at SILVER level.
            (NFTMaestry.Levels _levelSilver) = nftMaestry.maestryLevels(i);
            uint256 levelSilver = uint256(_levelSilver);
            assertEq(silver, levelSilver);

            // Upgrade newAddress's NFT to GOLD level and verify the upgrade event.
            vm.expectEmit();
            emit UpgradedLevel(newAddress, NFTMaestry.Levels.GOLD);
            nftMaestry.upGradeNft();

            // Verify that newAddress's NFT is now at GOLD level.
            (NFTMaestry.Levels _levelGold) = nftMaestry.maestryLevels(i);
            uint256 levelGold = uint256(_levelGold);      
            assertEq(gold, levelGold);   

            // Attempt to upgrade NewAddress's NFT again, which should not change its level.
            nftMaestry.upGradeNft();
            (NFTMaestry.Levels _levelGold1) = nftMaestry.maestryLevels(i);
            uint256 levelGold1 = uint256(_levelGold1);      
            assertEq(gold, levelGold1);  
            vm.stopPrank();                                   

        }     
    } 

    /**
     * @dev Test function to perform fuzz testing by adding random addresses to the whitelist.
     */
    function test_FuzzAddWhiteList() public {
        //Generate a random address.
        for(uint256 i; i < 1000; i++) {
            uint256 randomValue = uint256(keccak256(abi.encodePacked(39365 days + i)));
            address newAddress = address(uint160(randomValue % 1000000));     

            // Revert if any address calls the function and it's not the owner.
            vm.prank(newAddress);
            vm.expectRevert();
            nftMaestry.addWhiteList(newAddress);

            // The owner adds random addresses to the whitelist.
            vm.prank(owner);
            nftMaestry.addWhiteList(newAddress);
            (bool added) = nftMaestry.whiteList(newAddress);
            assertTrue(added);

        }        

    }
}
