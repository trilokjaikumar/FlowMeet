# FlowMeet

FlowMeet is an experimental macOS automation project exploring how native system automation, external APIs, and AI services can be composed into a resilient meeting assistant.

The project focuses on system design, OS-level automation, and architectural tradeoffs rather than feature completeness. It is intentionally iterative and evolving.

---

## Project Overview

FlowMeet detects upcoming meetings from Google Calendar, extracts conferencing metadata (such as Zoom join links), and initiates macOS-level workflows at meeting start time.

The system also prototypes optional AI-assisted features such as meeting summaries and contextual feedback using OpenAI APIs.

This project has been under active development for several months and is not presented as a finished product.

---

## Core Capabilities

- Ingests scheduled meetings via the Google Calendar API  
- Parses meeting metadata to identify and launch Zoom join links automatically  
- Implements native macOS automation using Swift and SwiftUI  
- Prototypes AI-assisted meeting summaries and talking points via OpenAI  
- Emphasizes privacy-aware workflows and explicit user control  

---

## Architecture & Design Goals

FlowMeet is structured around a clear separation of concerns:

### Calendar Ingestion Layer
Responsible for authentication, event retrieval, and metadata parsing.

### Automation & Orchestration Layer
Coordinates timing, system-level actions, and workflow execution.

### Native UI Layer (SwiftUI)
Provides a lightweight macOS interface for visibility and user control.

### AI Services Layer (Optional)
Handles external AI requests with fault tolerance and graceful degradation.

Primary design goals include:
- Modularity and extensibility  
- Graceful handling of unreliable external services  
- Privacy-conscious credential and data management  
- Readability and maintainability over premature optimization  

---

## Tech Stack

- Swift / SwiftUI (macOS, Xcode)
- Google Calendar API
- OpenAI API
- macOS Keychain for secure credential storage  

API credentials are injected at runtime and are never hardcoded.

---

## Current Status

FlowMeet is an early-stage, evolving project.

Some features are partial or experimental, and the codebase reflects ongoing architectural exploration rather than a finalized product.

This repository is public to showcase:
- System design decisions  
- Native macOS automation patterns  
- Integration of external APIs into OS-level workflows  

---

## What I’ve Learned So Far

- Designing modular systems that integrate unreliable external services  
- Managing authentication and secure credential storage on macOS  
- Coordinating time-based automation with user-visible UI  
- Balancing product ambition with architectural clarity in solo projects  

---

## Future Directions

- Improved fault tolerance and offline behavior  
- Expanded automation workflows beyond meeting joins  
- Refined UI/UX for better transparency and control  
- Continued architectural refinement as features mature  

---

## Use of AI in Development

AI tools were used during development to:
- Accelerate prototyping  
- Explore architectural alternatives  
- Sanity-check implementation approaches  

All generated code and design suggestions were:
- Reviewed and modified manually  
- Integrated selectively based on system constraints  
- Refactored to align with project architecture and macOS-specific requirements  

Final design decisions, system boundaries, and tradeoffs were made deliberately, with AI serving as a development aid rather than a source of truth.

---

## License & Usage

This repository is **not open source**.

The code is publicly visible for **educational and portfolio review purposes only**.  
No permission is granted to use, modify, deploy, redistribute, or create derivative works from this code without explicit prior written consent from the copyright holder.
