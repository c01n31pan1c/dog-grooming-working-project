# ADR-001: Game Engine Selection

**Status:** Proposed  
**Date:** 2026-06-24  
**Deciders:** Project Lead

## Context

We need a game engine for a competitive dog grooming time-management mobile game (F2P, 13+, fully offline). Hard requirements: rotatable 3D dog models with per-region interaction zones, shell-textured fur rendering, tool-based grooming mechanics with future gesture input, monetization via AdMob/IAP, and 60fps on mid-range iOS + Android devices.

## Options Evaluated

### 1. Unity (C# / URP) -- RECOMMENDED

- **Mobile perf:** URP is purpose-built for ARM GPUs. GPU Resident Drawer (Unity 6) cuts rendering CPU cost up to 50%. Proven 60fps pipeline; ASTC compression first-class. Minimal APK ~35-60 MB.
- **3D/Fur:** Custom shell-texture shaders in ShaderGraph/HLSL well-documented. Existing open-source fur shader references (e.g., Sorumi/UnityFurShader). URP stylized art pipeline is mature.
- **Input:** New Input System supports multi-touch, gestures, tool-select patterns natively. Easily extensible.
- **Monetization:** First-party AdMob, Unity Ads, IAP, Analytics SDKs. Mediation layers (AppLovin MAX, LevelPlay) are officially maintained. Best-in-class for F2P mobile.
- **Offline:** Fully offline by default; no engine-level online dependency.
- **Learning curve:** Moderate. Massive tutorial ecosystem; C# is approachable. Largest community for mobile game dev.
- **Asset store:** Extensive animal/pet model packs, grooming-adjacent assets, shader tutorials.
- **Cross-platform:** One-click iOS + Android builds. Mature CI/CD tooling.

### 2. Godot 4.x (GDScript/C#)

- **Mobile perf:** Improving rapidly (native Metal in 4.4, Vulkan Android optimizations, physics interpolation). Smallest APK (~25-35 MB). However, 3D mobile renderer still maturing vs Unity URP.
- **3D/Fur:** Custom shaders possible in Godot Shading Language but fewer mobile-optimized fur references. Shell texturing doable but less community precedent on mobile.
- **Input:** Solid touch/gesture support. Adequate for this scope.
- **Monetization:** AdMob via community plugins (godot-sdk-integrations, Poing Studios). Active but not vendor-maintained. IAP requires separate community plugins. Higher integration risk.
- **Offline:** Fully offline.
- **Learning curve:** Lowest barrier. GDScript is beginner-friendly. Excellent for learning.
- **Asset store:** Growing but significantly smaller than Unity for 3D pet/animal content.
- **Cross-platform:** Android export via GABE (4.7). iOS export works but less battle-tested at scale.

### 3. Unreal Engine 5 (C++/Blueprints)

- **Mobile perf:** Desktop-first architecture. Achieving 60fps requires disabling Nanite/Lumen and using Forward Mobile renderer. APK baseline 150-300 MB. Long C++ compile times.
- **3D/Fur:** Most powerful shader system (Niagara, material editor) but overkill for stylized mobile. Shell fur trivial to implement but hard to optimize for mobile budget.
- **Input:** Enhanced Input system is flexible but designed for console/PC patterns.
- **Monetization:** No first-party mobile ad/IAP SDKs. Manual Java/ObjC bridging required.
- **Offline:** Fully offline.
- **Learning curve:** Steepest. C++ complexity; Blueprint visual scripting helps but overall heaviest ramp.
- **Asset store:** Marketplace skews AAA/desktop. Few mobile pet-game assets.
- **Cross-platform:** Mobile builds work but are slow and bloated for this scope.

## Decision

**Unity (C# / URP)** is the recommended engine.

## Rationale

Unity wins on the axes that matter most for this project: proven mobile 60fps pipeline (URP), the strongest F2P monetization SDK ecosystem, extensive shell-fur shader community references, and the deepest mobile-specific asset store. The learning curve is moderate but offset by the largest tutorial community in game dev.

## Rejected Alternatives

- **Godot 4.x:** Rejected due to immature monetization SDK ecosystem (community-only AdMob/IAP plugins add integration risk for a F2P title) and fewer 3D mobile fur-shader references. Strong contender if monetization were not critical.
- **Unreal Engine 5:** Rejected as fundamentally over-engineered for a stylized mobile game. The 150+ MB APK floor, desktop-first architecture requiring feature disabling for mobile perf, absence of ad/IAP SDKs, and steepest learning curve make it unsuitable.
