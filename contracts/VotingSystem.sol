// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingSystem is Ownable {

    // Deadline for voter registration
    uint256 public votingDeadline;

    // Voter details struct
    struct VoterInfo {
        address votedFor;
        bool isRegistered;
        bool isVoted;
        bool isBlacklisted;
    }
    // Mapping to store each voter's information
    mapping(address => VoterInfo) public voter;
    // Mapping to store vote counts per candidate
    mapping(address => uint256) public votedForCount;
    // Mapping to check candidate is valid or not
    mapping(address => bool) public isValidCandidate;

    // List of registered voters
    address[] private voters;
    // List of valid candidates
    address[] private candidateList;

    // Custom errors
    error VotingClosed();
    error AlreadyRegistered();
    error NotRegistered();
    error BlacklistedVoter();
    error NotValidCandidate();

    // Constructor sets the registration deadline and initializes candidates
    constructor(uint256 _deadline, address[] memory _candidates) 
        Ownable(msg.sender) {
        votingDeadline = _deadline;
        for (uint256 i; i < _candidates.length; ) {
            candidateList.push(_candidates[i]);
            isValidCandidate[_candidates[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Register as a voter before the deadline
    function registerVoter() external {
        if(block.timestamp > votingDeadline) {
            revert VotingClosed();
        }
        VoterInfo storage rVoter = voter[msg.sender];
        if(rVoter.isRegistered) {
            revert AlreadyRegistered();
        }
        rVoter.isRegistered = true;
        voters.push(msg.sender); 
    }

    /// @notice Cast a vote for a valid candidate
    function vote(address _candidate) external {
        VoterInfo storage vVoter = voter[msg.sender];
        if(!vVoter.isRegistered) {
            revert NotRegistered();
        }
        if(vVoter.isBlacklisted) {
            revert BlacklistedVoter();
        }
        if(!isValidCandidate[_candidate]) {
            revert NotValidCandidate();
        }
        if(vVoter.isVoted) {
            votedForCount[_candidate]--;
            vVoter.isVoted = false;
            vVoter.isBlacklisted = true;
            return;
        }
        votedForCount[_candidate]++;
        vVoter.votedFor = _candidate;
        vVoter.isVoted = true;
    }

    /// @notice Owner can update the registration deadline
    function setVotingDeadline(uint256 _deadline) external onlyOwner {
        votingDeadline = _deadline;
    }

    /// @notice Returns the list of registered voters
    function getVoters() external view returns(address[] memory) {
        return voters;
    }

    /// @notice Checks if a voter is blacklisted
    function isBlacklistedVoter(address _voter) external view returns(bool) {
        return voter[_voter].isBlacklisted;
    }

    /// @notice Returns the list of valid candidates
    function getCandidatesList() external view returns(address[] memory) {
        return candidateList;
    }
}