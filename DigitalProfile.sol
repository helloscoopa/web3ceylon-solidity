// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DigitalProfile {
    // === FEATURE 1: PROFESSIONAL PROFILE ===
    struct Profile {
        string name;
        string bio;
        string email;
        string linkedin;
        string github;
        string[] skills;
        bool isPublic;
    }
    
    Profile private myProfile;
    address public owner;
    
    mapping(address => bool) public connectedCards;
    mapping(address => bool) public pendingRequests; // Requests I sent
    mapping(address => bool) public incomingRequests; // Requests I received
    address[] public connectionsList;
    uint256 public totalConnections;
    
    struct Endorsement {
        address endorser;
        string skill;
        uint8 rating; // 1-10
        string comment;
        uint256 timestamp;
    }
    
    mapping(string => Endorsement[]) public endorsementsForSkill;
    mapping(address => mapping(string => bool)) public hasEndorsedSkill;
    string[] public endorsedSkills; // Track which skills have endorsements
    
    event ProfileUpdated(address indexed owner);
    event ConnectionRequested(address indexed from, address indexed to);
    event ConnectionAccepted(address indexed friend1, address indexed friend2);
    event SkillEndorsed(address indexed endorser, address indexed endorsed, string skill, uint8 rating);
    
    constructor(
        string memory _name,
        string[] memory _skills
    ) {
        owner = msg.sender;
        myProfile.name = _name;
        myProfile.skills = _skills;
        myProfile.isPublic = true;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    // === FEATURE 1: PROFILE MANAGEMENT ===
    function updateProfile(
        string memory _name,
        string memory _bio,
        string memory _email,
        string memory _linkedin,
        string memory _github
    ) external onlyOwner {
        myProfile.name = _name;
        myProfile.bio = _bio;
        myProfile.email = _email;
        myProfile.linkedin = _linkedin;
        myProfile.github = _github;
        
        emit ProfileUpdated(owner);
    }
    
    function updateSkills(string[] memory _skills) external onlyOwner {
        myProfile.skills = _skills;
        emit ProfileUpdated(owner);
    }
    
    function setProfileVisibility(bool _isPublic) external onlyOwner {
        myProfile.isPublic = _isPublic;
    }
    
    // === FEATURE 2: CONNECTION MANAGEMENT ===
    function sendConnectionRequest(address _targetCard) external onlyOwner {
        require(_targetCard != address(this), "Cannot connect to yourself");
        require(!connectedCards[_targetCard], "Already connected");
        require(!pendingRequests[_targetCard], "Request already sent");
        
        pendingRequests[_targetCard] = true;
        
        // Try to notify the target card
        try IBusinessCard(_targetCard).receiveConnectionRequest(address(this)) {
            emit ConnectionRequested(address(this), _targetCard);
        } catch {
            // Target card might not support this function, revert the request
            pendingRequests[_targetCard] = false;
            revert("Failed to send connection request");
        }
    }
    
    function receiveConnectionRequest(address _fromCard) external {
        require(!connectedCards[_fromCard], "Already connected");
        require(!incomingRequests[_fromCard], "Already requested");
        incomingRequests[_fromCard] = true;
    }
    
    function acceptConnectionRequest(address _fromCard) external onlyOwner {
        require(incomingRequests[_fromCard], "No pending request from this address");
        require(!connectedCards[_fromCard], "Already connected");
        
        // Accept the connection
        connectedCards[_fromCard] = true;
        connectionsList.push(_fromCard);
        totalConnections++;
        
        // Remove from pending
        incomingRequests[_fromCard] = false;
        
        // Try to notify the other card to complete mutual connection
        try IBusinessCard(_fromCard).confirmConnection(address(this)) {
            emit ConnectionAccepted(_fromCard, address(this));
        } catch {
            // Other card might not support confirmation, but connection is still valid
        }
    }
    
    // Called by other card when they accept our request
    function confirmConnection(address _friendCard) external {
        require(pendingRequests[_friendCard], "No pending request to this address");
        
        connectedCards[_friendCard] = true;
        connectionsList.push(_friendCard);
        totalConnections++;
        
        // Remove from pending
        pendingRequests[_friendCard] = false;
        
        emit ConnectionAccepted(address(this), _friendCard);
    }
    
    function rejectConnectionRequest(address _fromCard) external onlyOwner {
        require(incomingRequests[_fromCard], "No pending request from this address");
        incomingRequests[_fromCard] = false;
    }
    
    // === FEATURE 3: SKILL ENDORSEMENTS ===
    function endorseSkill(
        address _targetCard,
        string memory _skill,
        uint8 _rating,
        string memory _comment
    ) external onlyOwner {
        require(_rating >= 1 && _rating <= 10, "Rating must be between 1-10");
        require(connectedCards[_targetCard], "Must be connected to endorse");
        require(!hasEndorsedSkill[_targetCard][_skill], "Already endorsed this skill");
        
        // Try to add endorsement to target card
        try IBusinessCard(_targetCard).receiveEndorsement(
            address(this), _skill, _rating, _comment
        ) {
            hasEndorsedSkill[_targetCard][_skill] = true;
            emit SkillEndorsed(address(this), _targetCard, _skill, _rating);
        } catch {
            revert("Failed to endorse skill");
        }
    }
    
    function receiveEndorsement(
        address _endorserCard,
        string memory _skill,
        uint8 _rating,
        string memory _comment
    ) external {
        require(connectedCards[_endorserCard], "Must be connected to receive endorsement");
        
        // Add endorsement
        endorsementsForSkill[_skill].push(Endorsement({
            endorser: _endorserCard,
            skill: _skill,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        }));
        
        // Track that this skill has endorsements (for easy lookup)
        if (endorsementsForSkill[_skill].length == 1) {
            endorsedSkills.push(_skill);
        }
    }
    
    // === FEATURE 4: NETWORK TRACKING ===
    function getConnections() external view returns (address[] memory) {
        return connectionsList;
    }
    
    function getConnectionCount() external view returns (uint256) {
        return totalConnections;
    }
    
    function checkConnection(address _card) external view returns (bool) {
        return connectedCards[_card];
    }
    
    function getMyProfile() external view returns (
        string memory name,
        string memory bio,
        string[] memory skills,
        string memory email,
        string memory linkedin,
        string memory github,
        bool isPublic,
        uint256 connections
    ) {
        require(myProfile.isPublic, "Profile is not public");

        return (
            myProfile.name,
            myProfile.bio,
            myProfile.skills,
            myProfile.email,
            myProfile.linkedin,
            myProfile.github,
            myProfile.isPublic,
            totalConnections
        );
    }
    
    function getSkillEndorsements(string memory _skill) 
        external view returns (Endorsement[] memory) {
        return endorsementsForSkill[_skill];
    }
    
    function getAllEndorsedSkills() external view returns (string[] memory) {
        return endorsedSkills;
    }
    
    function getEndorsementSummary() external view returns (
        string[] memory skills,
        uint256[] memory counts,
        uint256[] memory averageRatings
    ) {
        skills = new string[](endorsedSkills.length);
        counts = new uint256[](endorsedSkills.length);
        averageRatings = new uint256[](endorsedSkills.length);
        
        for (uint256 i = 0; i < endorsedSkills.length; i++) {
            string memory skill = endorsedSkills[i];
            Endorsement[] memory endorsements = endorsementsForSkill[skill];
            
            skills[i] = skill;
            counts[i] = endorsements.length;
            
            if (endorsements.length > 0) {
                uint256 totalRating = 0;
                for (uint256 j = 0; j < endorsements.length; j++) {
                    totalRating += endorsements[j].rating;
                }
                averageRatings[i] = totalRating / endorsements.length;
            }
        }
        
        return (skills, counts, averageRatings);
    }
    
    function getPublicProfile() external view returns (
        string memory name,
        string memory bio,
        bool isPublic
    ) {
        return (myProfile.name, myProfile.bio, myProfile.isPublic);
    }
}

// Interface for interacting with other business cards
interface IBusinessCard {
    function receiveConnectionRequest(address _fromCard) external;
    function confirmConnection(address _friendCard) external;
    function receiveEndorsement(address _endorserCard, string memory _skill, uint8 _rating, string memory _comment) external;
}