// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract SimpleDigitalProfile {
    // State variables to store profile information
    string public name;
    string public bio;
    string public email;
    address public owner;

    // Array to store user's skills
    string[] private skills;

    // Struct to store self-assessed skill levels
    struct SkillEndorsement {
        string skill;
        uint8 rating; // 1-10 scale
        string comment;
        uint256 timestamp;
        address endorser;
    }

    // Mapping from skill name to array of endorsements
    mapping(string => SkillEndorsement[]) private skillEndorsements;

    // Mapping to check if an address has already endorsed a specific skill
    mapping(string => mapping(address => bool)) private hasEndorsed;

    // Array to track which skills have been endorsed
    string[] private endorsedSkills;

    // Event emitted when profile is updated
    event ProfileUpdated(address indexed owner);

    // Event emitted when skills are updated
    event SkillsUpdated(address indexed owner);

    // Event emitted when skill is endorsed
    event SkillEndorsed(address indexed endorser, address indexed skillOwner, string skill, uint8 rating);

    // Constructor sets the initial name and owner
    constructor(string memory _name) {
        owner = msg.sender;
        name = _name;
    }

    // Modifier to restrict access to owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    // Function to update basic profile information
    function updateProfile(
        string calldata _name,
        string calldata _bio,
        string calldata _email
    ) external onlyOwner {
        name = _name;
        bio = _bio;
        email = _email;

        emit ProfileUpdated(owner);
    }

    // Function to update skills
    function updateSkills(string[] memory _skills) external onlyOwner {
        skills = _skills;
        emit SkillsUpdated(owner);
    }

    // Function to add a single skill
    function addSkill(string calldata _skill) external onlyOwner {
        skills.push(_skill);
        emit SkillsUpdated(owner);
    }

    // Function to get number of skills
    function getSkillCount() external view returns (uint256) {
        return skills.length;
    }

    // Internal function to check if a skill exists in the owner's skills
    function _skillExists(string calldata _skill) internal view returns (bool) {
        for (uint256 i = 0; i < skills.length; i++) {
            if (keccak256(abi.encodePacked(skills[i])) == keccak256(abi.encodePacked(_skill))) {
                return true;
            }
        }
        return false;
    }

    // Function to endorse a skill
    function endorseSkill(
        string calldata _skill,
        uint8 _rating,
        string calldata _comment
    ) external {
        require(_rating >= 1 && _rating <= 10, "Rating must be between 1-10");
        require(!hasEndorsed[_skill][msg.sender], "You have already endorsed this skill");
        require(_skillExists(_skill), "Skill does not exist in profile");

        // Check if this is the first endorsement for this skill
        bool isFirstEndorsementOfSkill = skillEndorsements[_skill].length == 0;

        // Create the endorsement
        skillEndorsements[_skill].push(SkillEndorsement({
            skill: _skill,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp,
            endorser: msg.sender
        }));

        // Mark that this address has endorsed this skill
        hasEndorsed[_skill][msg.sender] = true;

        // Add to endorsed skills array if it's a new skill
        if (isFirstEndorsementOfSkill) {
            endorsedSkills.push(_skill);
        }

        emit SkillEndorsed(msg.sender, owner, _skill, _rating);
    }

    // Function to get all endorsements for a specific skill
    function getSkillEndorsements(string calldata _skill) external view returns (SkillEndorsement[] memory) {
        return skillEndorsements[_skill];
    }

    // Function to check if an address has endorsed a specific skill
    function hasEndorsedSkill(string calldata _skill, address _endorser) external view returns (bool) {
        return hasEndorsed[_skill][_endorser];
    }

    // Function to get endorsement summary with average ratings
    function getEndorsementSummary() external view returns (
        string[] memory skillNames,
        uint16[] memory averageRatings,
        uint256[] memory endorsementCounts,
        uint256 totalSkills
    ) {
        skillNames = new string[](endorsedSkills.length);
        averageRatings = new uint16[](endorsedSkills.length);
        endorsementCounts = new uint256[](endorsedSkills.length);

        for (uint256 i = 0; i < endorsedSkills.length; i++) {
            string memory skill = endorsedSkills[i];
            skillNames[i] = skill;

            SkillEndorsement[] memory endorsements = skillEndorsements[skill];
            endorsementCounts[i] = endorsements.length;

            // Calculate average rating
            if (endorsements.length > 0) {
                uint256 totalRating = 0;
                for (uint256 j = 0; j < endorsements.length; j++) {
                    totalRating += endorsements[j].rating;
                }
                averageRatings[i] = uint16((totalRating * 100) / endorsements.length);
            }
        }

        return (skillNames, averageRatings, endorsementCounts, endorsedSkills.length);
    }
}