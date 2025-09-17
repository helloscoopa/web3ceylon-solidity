# SimpleDigitalProfile

A decentralized digital profile smart contract that allows users to create and manage their professional profile on-chain, complete with skill endorsements from other users.

## Overview

SimpleDigitalProfile is a Solidity smart contract that enables users to:
- Create and maintain a digital profile with basic information (name, bio, email)
- List their professional skills
- Receive skill endorsements from other blockchain addresses
- View endorsement summaries with average ratings

## Features

### Profile Management
- **Owner-only profile updates**: Only the profile owner can update their basic information
- **Basic profile fields**: Name, bio, and email
- **Skills management**: Add individual skills or update the entire skills array

### Skill Endorsements
- **Peer endorsements**: Any address can endorse skills with ratings (1-10 scale) and comments
- **Duplicate prevention**: Each address can only endorse each skill once
- **Timestamped records**: All endorsements include blockchain timestamps
- **Endorser tracking**: Full transparency of who provided each endorsement

### Data Access
- **Endorsement queries**: Retrieve all endorsements for specific skills
- **Summary statistics**: Get average ratings and endorsement counts across all skills
- **Endorsement verification**: Check if specific addresses have endorsed particular skills

## Contract Structure

### State Variables
- `name`, `bio`, `email`: Basic profile information
- `owner`: Contract deployer's address
- `skills[]`: Array of user's skills
- `skillEndorsements`: Mapping of skills to their endorsement arrays
- `hasEndorsed`: Tracking mapping to prevent duplicate endorsements
- `endorsedSkills[]`: Array of skills that have received endorsements

### Key Functions

#### Profile Management
- `updateProfile(name, bio, email)`: Update basic profile info (owner only)
- `updateSkills(skills[])`: Replace entire skills array (owner only)
- `addSkill(skill)`: Add a single skill (owner only)

#### Endorsements
- `endorseSkill(skill, rating, comment)`: Endorse a skill with 1-10 rating
- `getSkillEndorsements(skill)`: Retrieve all endorsements for a skill
- `hasEndorsedSkill(skill, endorser)`: Check if address has endorsed a skill
- `getEndorsementSummary()`: Get overview of all endorsed skills with averages

#### View Functions
- `getSkillCount()`: Returns total number of skills
- All public state variables are automatically viewable

## Events

- `ProfileUpdated`: Emitted when basic profile is updated
- `SkillsUpdated`: Emitted when skills are modified
- `SkillEndorsed`: Emitted when a skill receives an endorsement

## Usage

1. **Deploy** the contract with an initial name
2. **Update profile** with bio and email using `updateProfile()`
3. **Add skills** using `addSkill()` or `updateSkills()`
4. **Others endorse** your skills using `endorseSkill()`
5. **View endorsements** using `getEndorsementSummary()` or `getSkillEndorsements()`

## Requirements

- Solidity ^0.8.19
- Endorsement ratings must be between 1-10
- Only the contract owner can update profile and skills
- Each address can endorse each skill only once

## License

MIT License