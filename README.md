# 3D Dungeon Game

A compact third-person 3D dungeon vertical slice created as an AI coding benchmark.

## Overview

The game is set inside a castle-style dungeon where the player explores the environment, navigates different pathways and hazards, encounters an enemy guarding a locked door, and progresses to the next area after defeating the enemy.

## Vertical Slice

Core gameplay loop:

**Explore the dungeon → Navigate hazards and pathways → Reach the guarded door → Defeat the enemy → Unlock the door → Progress to the next area**

## Benchmark

This repository is used to evaluate AI models on incremental Godot game-development tasks.

Each task is built on top of the previous task's completed implementation.

### Branch Structure

The `main` branch contains the clean base game.

When an AI model fails a task:

```text
main / previous solution
        │
        └── task/<task-name>/base
                    │
                    └── task/<task-name>/solution
```

The `base` branch represents the game before the task is implemented.

The `solution` branch contains the corrected implementation of the task along with its `RUBRIC.md` file.

The solution branch of one task becomes the base for the next task.

## Current Base Game

The initial base game contains:

* Third-person player
* WASD movement
* Basic camera
* Walkable 3D dungeon environment

Task-specific gameplay systems are added in subsequent benchmark tasks.

## Engine

* Godot 4
* 3D
* Compatibility renderer

## AI Models

Tasks in this repository are evaluated using AI coding models such as:

* Claude Opus 5
* GPT-5.8

## Documentation

Detailed benchmark documentation, including task prompts, observed failures, expected outcomes, and gameplay evidence, will be added as the vertical slice progresses.
