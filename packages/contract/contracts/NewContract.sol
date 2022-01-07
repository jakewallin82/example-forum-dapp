//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Ultimatum {
  using Counters for Counters.Counter;
  
  /**
    * @notice Represents a single ultimatum proposal or reception. 
    */
  struct Proposal {
    /// @notice Unique item id, assigned at creation time.
    uint256 id;

    /// @notice address of author.
    address author;

    /// @notice block number when item was submitted
    uint256 createdAtBlock;

    /// amount proposed, accepted, or rejected
    uint256 amount;

    //represents whether proposal is still open
    bool open;

    /// @notice IPFS CID of item content.
    string contentCID;
  }

  struct Reception {
    /// @notice Unique item id, assigned at creation time.
    uint256 id;

    /// @notice address of author.
    address author;

    /// @notice block number when item was submitted
    uint256 createdAtBlock;

    /// amount proposed, accepted, or rejected
    uint256 amount;

    //represents whether proposal was accepted or not
    bool accepted;

    //id of proposal object
    uint256 proposalID;

    /// @notice IPFS CID of item content.
    string contentCID;
  }

  /// @notice Vote state for a particular post or comment.
  struct VoteCount {
    // mapping of hash(voterAddress) => vote, where +1 == upvote, -1 == downvote, and 0 == not yet voted
    mapping(bytes32 => int8) votes;

    // accumulation of all votes for this content
    int256 total;
  }

  /// @dev counter for issuing item ids
  Counters.Counter private proposalIdCounter;
  Counters.Counter private receptionIdCounter;
  /// @dev maps item id to vote state
  mapping(uint256 => VoteCount) private itemVotes;

  /// @dev maps author address total post & comment vote score
  mapping(address => int256) private authorKarma;

  /// @dev maps item id to item
  mapping(uint256 => Proposal) private proposals;
  mapping(uint256 => Reception) private receptions;

  /// @notice NewItem events are emitted when a post or comment is created.
  event NewProposal(
    uint256 indexed id,
    address indexed author
  );

  event NewReception(
    uint256 indexed id,
    address indexed author
  );

  /**
    * @notice Create a new post.
    * @param amount - Number 1-10 representing split of funds for proposer
    * @param contentCID IPFS CID of post content object.
   */
  function addProposal(uint256 amount, string memory contentCID) public {
    proposalIdCounter.increment();
    uint256 id = proposalIdCounter.current();
    address author = msg.sender;

    proposals[id] = Proposal(id, author, block.number, amount, true, contentCID);
    emit NewProposal(id, author);
  }

  /**
    * @notice Fetch a item by id.
    * @dev reverts if no item exists with the given id.
    */
  function getProposal(uint256 proposalId) public view returns (Proposal memory) {
    require(proposals[proposalId].id == proposalId, "No item found");
    return proposals[proposalId];
  }

  function getReception(uint256 receptionId) public view returns (Reception memory) {
    require(receptions[receptionId].id == receptionId, "No item found");
    return receptions[receptionId];
  }


  /** 
    * @notice Adds a comment to a post or another comment.
    * @dev will revert if the parent item does not exist.
    * @param proposalId the id of an existing item
    * @param contentCID IPFS CID of comment content object
    */
  function addReception(uint256 proposalId, bool accepted, string memory contentCID) public {
    require(proposals[proposalId].id == proposalId, "Proposal does not exist");
    require(proposals[proposalId].open == true, "Proposal is closed");

    receptionIdCounter.increment();
    uint256 id = receptionIdCounter.current();
    address author = msg.sender;

    proposals[proposalId].open = false;

    uint256 reception_amount;
    reception_amount = 10 - proposals[proposalId].amount;
    if (!accepted) reception_amount = 0;

    receptions[id] = Reception(id, author, block.number, reception_amount, accepted, proposalId, contentCID);
    emit NewReception(id, author);
  }

}
