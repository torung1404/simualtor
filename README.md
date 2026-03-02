# Anime Simulator - Roblox Game Architecture

A complete menu-driven anime simulator for Roblox, built following clean architecture patterns with server-authoritative design.

## Project Structure

```
game/
  ReplicatedStorage/
    Shared/
      Configs/                  -- All game content defined as data tables
        ArcsConfig.lua          -- Arc definitions (zones, enemies, upgrades)
        EnemiesConfig.lua       -- Enemy stat tables with drop tables
        JobsConfig.lua          -- Job definitions with tick timers
        UpgradesConfig.lua      -- Upgrade definitions with cost curves
        ItemsConfig.lua         -- Item/relic definitions, collection sets
        SeasonConfig.lua        -- Season parameters, ranked tiers, daily quests
      NetSchema/
        RemoteNames.lua         -- Single source of truth for remote names
        PayloadTypes.lua        -- Payload validators for all remotes
      Utils/
        NumberFormat.lua        -- Number abbreviation (1.2K, 3.4M)
        TableUtils.lua          -- Table manipulation utilities
        MathUtils.lua           -- Math helpers (clamp, lerp, weighted random)

  ServerScriptService/
    ServerInit.lua              -- Main server entry point, wires everything up
    Services/
      PlayerDataService.lua     -- Load, save, cache, migrate, session lock
      PlayerStateMachine.lua    -- State management (InMenu, InCombat, etc.)
      EconomyService.lua        -- Currency operations, reward calculations
      CombatService.lua         -- Fight resolution, loot drops
      UpgradeService.lua        -- Buy/level upgrades, effect calculation
      JobService.lua            -- Job ticking, claim, anti-macro detection
      TutorialService.lua       -- 6-step tutorial tracking and validation
      RankService.lua           -- Ranked battles, season management
      AntiCheatService.lua      -- Rate limiting, violation tracking, audit log
    RemoteHandlers/
      CombatHandler.lua         -- Routes combat remotes with validation
      EconomyHandler.lua        -- Routes buy/sell/equip remotes
      JobHandler.lua            -- Routes job remotes
      RankHandler.lua           -- Routes ranked remotes

  StarterPlayerScripts/
    ClientInit.lua              -- Main client entry point
    Controllers/
      UIController.lua          -- UI state, tab management, event system
      CombatViewController.lua  -- Combat display formatting
      JobViewController.lua     -- Job display formatting
      UpgradeViewController.lua -- Upgrade display formatting
      TutorialController.lua    -- Tutorial overlay driver
      SoundController.lua       -- SFX triggers
    ViewModels/
      PlayerViewModel.lua       -- Player stats formatting for UI
      EnemyViewModel.lua        -- Enemy info formatting for UI
```

## Design Principles

1. **Data-Driven**: All content defined in Config tables. Adding a new Arc = adding a table entry.
2. **Server-Authoritative**: Client sends intentions, server resolves everything.
3. **Single Responsibility**: Each Service handles exactly one domain.
4. **Dependency Injection**: Services receive references, not global access.
5. **Event-Driven UI**: Client subscribes to state changes, never polls.

## Core Gameplay Loop

```
Fight Enemy/Boss -> Receive Currency/XP/Drops -> Spend on Upgrades -> Unlock new Arc -> Repeat
```

## Architecture

- **Server**: Services handle game logic; Handlers validate and route remotes
- **Client**: Controllers manage UI state; ViewModels format data for display
- **Shared**: Configs and utilities used by both server and client

## Security

- 5-layer anti-exploit: payload validation, rate limiting, state machine, economic sanity, audit logging
- Session locking prevents data duplication
- All currency/stat changes are server-side only

## Content (Arc 1 - Shattered Gate)

- 5 regular enemies + 1 boss with shield/enrage mechanics
- 15 upgrades across damage, income, crit, drop rate, speed, and QoL
- 3 jobs with passive income
- 3 relics forming a collection set with permanent bonuses
- 6-step tutorial flow

## Implementation Status

- [x] Phase 1: Foundation (configs, data service, state machine, anti-cheat)
- [x] Phase 2: Core Loop (combat, upgrades, jobs, economy, tutorial)
- [x] Phase 3: Client Framework (controllers, view models, init scripts)
- [ ] Phase 4: Persistence & Safety (DataStore integration, full anti-cheat)
- [ ] Phase 5: Progression Systems (leaderboards, daily quests, collection book)
- [ ] Phase 6: Monetization & Social (gems shop, referrals, friend bonuses)
- [ ] Phase 7: Content Scaling (Arcs 2-5 activation, Train/Fish tabs)
- [ ] Phase 8: Polish (SFX/VFX, mobile UI pass, performance profiling)
