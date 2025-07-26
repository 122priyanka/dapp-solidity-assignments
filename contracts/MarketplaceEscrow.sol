// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketplaceEscrow is Ownable{
    struct Item {
        uint256 amount;
        address buyer;
        address seller;
        ItemStatus status;
    }

    enum ItemStatus {
        NotListed, Listed, Sold, Received, Disputed, Resolved
    }
    mapping(string => Item) public items;

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

    constructor() 
        Ownable(msg.sender) {
    }

    function ListItem(uint256 _amount, string memory _name) external {
        Item storage sItem = items[_name];
        if(sItem.seller != address(0)) revert ItemAlreadyListed();
        if(_amount == 0 || bytes(_name).length == 0) revert InvalidInput();
        sItem.amount = _amount;
        sItem.seller = msg.sender;
        sItem.status = itemStatus.Listed;
    }

    function Buy(string calldata _name) external payable {
        Item storage bItem = items[_name];
        if(bItem.status != itemStatus.Listed) revert ItemNotListed();
        if(bItem.buyer != address(0)) revert ItemSold();
        if(msg.value != bItem.amount) revert InvalidAmount();

        bItem.buyer = msg.sender;
        bItem.status = itemStatus.Sold;
    }

    function Confirmation(string calldata _name) external {
        Item storage cItem = items[_name];
        if(msg.sender != cItem.buyer) revert InvalidBuyer();
        if(cItem.status == itemStatus.Received) revert ItemAlreadyReceived();
        cItem.status = itemStatus.Received;

        (bool success, ) = (cItem.seller).call{value: cItem.amount}("");
        if(!success) revert FailedToSend();
    }

    function raiseDispute(string calldata _name) external {
        Item storage dItem = items[_name];
        if(msg.sender != dItem.buyer) revert InvalidBuyer();
        if(dItem.status == itemStatus.Received) revert ItemAlreadyReceived();
        dItem.status = itemStatus.Disputed;
    }

    function resolveDispute(string calldata _name, address _recipient) external onlyOwner {
        Item storage item = items[_name];
        if(item.status != itemStatus.Disputed) revert ItemNotInDispute();
        if(item.status == itemStatus.Resolved) revert ItemDisputeResolved();
        if(_recipient != item.buyer && _recipient != item.seller) revert InvalidRecipient();

        item.status = itemStatus.Resolved;

        (bool success, ) = payable(_recipient).call{value: item.amount}("");
        if(!success) revert FailedToSend();
    }
}