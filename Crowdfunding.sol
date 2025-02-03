
---

### **Example Solidity Contract (`contracts/Crowdfunding.sol`)**  
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Crowdfunding {
    struct Campaign {
        address owner;
        string title;
        string description;
        uint256 goal;
        uint256 fundsRaised;
        uint256 deadline;
        bool claimed;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public contributions;
    uint256 public campaignCount;

    event CampaignCreated(uint256 campaignId, string title, uint256 goal, uint256 deadline);
    event Funded(uint256 campaignId, address contributor, uint256 amount);
    event FundsClaimed(uint256 campaignId, uint256 amount);

    function createCampaign(string memory _title, string memory _description, uint256 _goal, uint256 _duration) public {
        require(_goal > 0, "Goal must be greater than zero");
        
        campaigns[campaignCount] = Campaign(msg.sender, _title, _description, _goal, 0, block.timestamp + _duration, false);
        emit CampaignCreated(campaignCount, _title, _goal, block.timestamp + _duration);
        campaignCount++;
    }

    function contribute(uint256 _campaignId) public payable {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(msg.value > 0, "Contribution must be greater than zero");

        campaign.fundsRaised += msg.value;
        contributions[_campaignId][msg.sender] += msg.value;
        emit Funded(_campaignId, msg.sender, msg.value);
    }

    function claimFunds(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(msg.sender == campaign.owner, "Only the owner can claim funds");
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(campaign.fundsRaised >= campaign.goal, "Funding goal not reached");
        require(!campaign.claimed, "Funds already claimed");

        campaign.claimed = true;
        payable(campaign.owner).transfer(campaign.fundsRaised);
        emit FundsClaimed(_campaignId, campaign.fundsRaised);
    }

    function getRefund(uint256 _campaignId) public {
        Campaign storage campaign = campaigns[_campaignId];
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(campaign.fundsRaised < campaign.goal, "Goal met, funds cannot be refunded");

        uint256 contribution = contributions[_campaignId][msg.sender];
        require(contribution > 0, "No funds to refund");

        contributions[_campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(contribution);
    }
}
