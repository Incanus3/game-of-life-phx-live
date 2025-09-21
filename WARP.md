# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Phoenix LiveView implementation of Conway's Game of Life, featuring real-time cellular automaton simulation with interactive controls. The application uses a GenServer for game state management and Phoenix PubSub for real-time updates.

## Essential Commands

### Development Setup
- `mix setup` - Install dependencies and setup assets (equivalent to `mix deps.get`, `mix assets.setup`, `mix assets.build`)
- `mix phx.server` - Start the Phoenix server (visit http://localhost:4000)
- `iex -S mix phx.server` - Start server with interactive Elixir shell

### Testing & Quality
- `mix test` - Run all tests
- `mix test test/specific_test.exs` - Run specific test file
- `mix test --failed` - Re-run only failed tests
- `mix precommit` - Run full quality check (compile with warnings as errors, format, test)

### Assets & Frontend
- `mix assets.setup` - Install frontend dependencies (Tailwind, esbuild)
- `mix assets.build` - Build frontend assets
- `mix assets.deploy` - Build and minify assets for production

## Architecture Overview

### Core Game Engine
- **`GameOfLife.Game`** (GenServer): Manages game state, evolution logic, and timing
  - Handles grid evolution using Conway's rules
  - Manages play/pause/reset controls
  - Supports variable speed and pattern loading
  - Broadcasts state changes via PubSub

### Web Layer
- **`GameOfLifeWeb.GameLive`** (LiveView): Interactive UI for the game
  - Real-time grid display with clickable cells
  - Control panel for play/pause, speed, patterns
  - Subscribes to game state changes via PubSub
- **Routes**: Root (`/`) serves static page, `/game` serves the LiveView

### Key Patterns
- **Real-time Updates**: Uses Phoenix.PubSub for broadcasting game state changes
- **State Management**: Game state centralized in GenServer, UI reactively updates
- **Grid Representation**: Uses map with `{row, col}` tuples as keys for efficient lookups
- **Pattern System**: Predefined cellular automaton patterns (glider, blinker, etc.)

### Application Structure
```
lib/
├── game_of_life/
│   ├── application.ex      # OTP supervision tree
│   └── game.ex            # Core game logic GenServer
└── game_of_life_web/
    ├── live/game_live.ex   # Main game interface
    ├── router.ex           # Route definitions
    └── components/         # Reusable UI components
```

## Development Guidelines

### Game Logic
- Grid coordinates use `{row, col}` tuple format consistently
- Cell states are boolean (true = alive, false = dead)
- Game evolution follows strict Conway's rules implementation
- Pattern loading centers patterns automatically on the grid

### LiveView Patterns
- Always broadcast state changes through PubSub for real-time updates
- Use `connected?(socket)` checks for PubSub subscriptions
- Handle both user interactions and server-pushed updates
- Grid rendering uses CSS Grid for responsive layout

### Performance Considerations
- Game grid uses Map for O(1) cell lookups
- Timer management prevents memory leaks on speed changes
- State broadcasts are throttled by generation timing

This implementation demonstrates real-time web applications with OTP concurrency patterns and reactive UI updates.