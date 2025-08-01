# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "Schlangenspiel" (Snake Game), a classic Snake game implementation built with Godot Engine 4.4. The game features a snake that moves around a grid, eating food to grow longer while avoiding collisions with itself.

## Development Commands

Since this is a Godot project, development is primarily done through the Godot Editor:

- **Run the game**: Open `main.tscn` in Godot Editor and press F5 or use the play button
- **Test scenes**: Use F6 to run the current scene in the editor
- **Export**: Use Project → Export in the Godot Editor

No traditional build/test/lint commands are present as this uses Godot's built-in systems.

## Architecture

### Core Components

- **main.gd** (`main.tscn`): Main game controller that manages game state, score, pause functionality, and coordinates between snake and food
- **snake.gd** (`snake.tscn`): Snake entity with movement logic, collision detection, growth mechanism, and game over signaling
- **food.gd** (`food.tscn`): Food item that randomly respawns when eaten
- **grid_background.gd**: Renders the grid background for visual reference

### Key Systems

- **Movement System**: Timer-based movement with configurable interval (0.05s default)
- **Grid System**: Uses global `block_size` setting (32px) for consistent positioning
- **Collision System**: Self-collision detection triggers game over signal
- **Screen Wrapping**: Snake wraps around screen edges
- **Pause System**: P key toggles pause state

### Global Configuration

The `project.godot` file contains important settings:
- `global/block_size=32`: Grid size used throughout the game
- Custom input action `pause_game` mapped to P key
- Viewport size: 1280x1024

### Scene Structure

- Main scene loads snake via code: `load("res://snake.gd").new()`
- Food instantiated from scene: `load("res://food.tscn").instantiate()`
- UI elements: ScoreLabel, GameOverRect, GameOverSound

## Development Notes

- All positioning uses grid coordinates multiplied by `block_size`
- Snake growth is handled by setting `new_segment` flag rather than immediate body expansion
- Game over state requires SPACE key to restart (reloads current scene)
- Audio feedback on game over with included sound file