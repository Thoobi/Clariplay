# Clariplay - Tiered Video Access Platform Smart Contract

## Overview

This smart contract implements a tiered video access platform on the Stacks blockchain. It allows users to purchase different tiers of access to video content, with varying prices and durations. The contract manages user subscriptions, video metadata, and access control.

## Key Features

1. **Tiered Access System**
   - Three tiers of access: Tier 1, Tier 2, and Tier 3
   - Each tier has a different price and subscription duration
   - Higher tiers have access to more content

2. **User Management**
   - Tracks user subscriptions, including tier level and expiration date
   - Counts the number of videos watched by each user

3. **Video Metadata**
   - Stores information about each video, including title and required access tier

4. **Access Control**
   - Checks user's subscription status and tier before allowing video access
   - Implements a hierarchical access system (higher tiers can access lower-tier content)

5. **Subscription Purchase**
   - Users can purchase subscriptions using STX tokens
   - Subscription duration varies based on the tier

6. **Admin Functions**
   - Contract owner can add new video metadata
   - Only the contract owner can record video views

## Core Functions

- `purchase-access`: Allows users to buy a subscription
- `add-video-metadata`: Enables the contract owner to add new videos
- `can-watch-video`: Checks if a user has permission to watch a specific video
- `record-video-view`: Records when a user watches a video

## Technical Details

- Implemented in Clarity, the smart contract language for Stacks
- Uses maps to store user and video data efficiently
- Implements read-only functions for querying user status and permissions
- Uses block height as a proxy for time in managing subscription expirations

This smart contract provides a robust foundation for a decentralized video platform with a tiered subscription model, offering flexibility for both users and content managers.
