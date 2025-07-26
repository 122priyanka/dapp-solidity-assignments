// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceEscrow is Ownable{
    // Struct to represent an item
    struct Item {
        uint256 amount;
        address buyer;
        address seller;
        ItemStatus status;
    }

    // Enum to represent item status
    enum ItemStatus {
        NotListed, Listed, Sold, Received, Disputed, Resolved
    }
    // Mapping to store items by their unique name
    mapping(string => Item) public items;

    // Custom errors
    error ItemAlreadyListed();
    error InvalidInput();
    error ItemNotListed();
    error ItemSold();
    error InvalidAmount();
    error InvalidBuyer();
    error ItemAlreadyReceived();
    error FailedToSend();
    error ItemNotInDispute();
    error InvalidRecipient();
    error ItemDisputeResolved();

    // Constructor to initialize the contract with the owner
    constructor() 
        Ownable(msg.sender) {
    }

    /// @notice Seller lists a unique item for sale
    function ListItem(uint256 _amount, string memory _name) external {
        Item storage sItem = items[_name];
        if(sItem.seller != address(0)) revert ItemAlreadyListed();
        if(_amount == 0 || bytes(_name).length == 0) revert InvalidInput();
        sItem.amount = _amount;
        sItem.seller = msg.sender;
        sItem.status = ItemStatus.Listed;
    }

    /// @notice Buyer initiates purchase, amounts are held in escrow
    function Buy(string calldata _name) external payable {
        Item storage bItem = items[_name];
        if(bItem.status != ItemStatus.Listed) revert ItemNotListed();
        if(bItem.buyer != address(0)) revert ItemSold();
        if(msg.value != bItem.amount) revert InvalidAmount();

        bItem.buyer = msg.sender;
        bItem.status = ItemStatus.Sold;
    }

    /// @notice Buyer confirms receipt, amounts are released to seller
    function Confirmation(string calldata _name) external {
        Item storage cItem = items[_name];
        if(msg.sender != cItem.buyer) revert InvalidBuyer();
        if(cItem.status == ItemStatus.Received) revert ItemAlreadyReceived();
        cItem.status = ItemStatus.Received;

        (bool success, ) = (cItem.seller).call{value: cItem.amount}("");
        if(!success) revert FailedToSend();
    }

    /// @notice Raise a dispute if the item is not received or not as described
    function raiseDispute(string calldata _name) external {
        Item storage dItem = items[_name];
        if(msg.sender != dItem.buyer) revert InvalidBuyer();
        if(dItem.status == ItemStatus.Received) revert ItemAlreadyReceived();
        dItem.status = ItemStatus.Disputed;
    }

    /// @notice Owner resolves the dispute and sends funds to either buyer or seller
    function resolveDispute(string calldata _name, address _recipient) external onlyOwner {
        Item storage item = items[_name];
        if(item.status != ItemStatus.Disputed) revert ItemNotInDispute();
        if(item.status == ItemStatus.Resolved) revert ItemDisputeResolved();
        if(_recipient != item.buyer && _recipient != item.seller) revert InvalidRecipient();

        item.status = ItemStatus.Resolved;

        (bool success, ) = payable(_recipient).call{value: item.amount}("");
        if(!success) revert FailedToSend();
    }
}