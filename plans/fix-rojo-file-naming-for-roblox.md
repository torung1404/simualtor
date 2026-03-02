# Fix Rojo File Naming for Roblox

## Problem
The game code does not execute in Roblox because the two entry-point scripts use `.lua` suffix instead of Rojo's required `.server.lua` / `.client.lua` suffixes. Rojo interprets all `.lua` files as **ModuleScripts**, which do not auto-execute.

## Root Cause
Rojo determines script type from the file name suffix:
- `.server.lua` --> Script -- auto-runs on server
- `.client.lua` --> LocalScript -- auto-runs on client  
- `.lua` --> ModuleScript -- only runs when required by another script

Both entry points are named `.lua`, so they become ModuleScripts that never start.

## Changes Required

### 1. Rename server entry point
- **From:** `ServerScriptService/ServerInit.lua`
- **To:** `ServerScriptService/ServerInit.server.lua`
- This file initializes all server services, creates RemoteEvents/RemoteFunctions, and wires up player lifecycle hooks. It must auto-execute as a Script.

### 2. Rename client entry point
- **From:** `StarterPlayerScripts/ClientInit.lua`
- **To:** `StarterPlayerScripts/ClientInit.client.lua`
- This file initializes all client controllers and view models. It must auto-execute as a LocalScript.

### 3. Verify require paths still work
After renaming, the `script.Parent` references inside both files should still resolve correctly because Rojo strips the `.server.lua` / `.client.lua` suffix when creating the instance name. The instance will still be named `ServerInit` and `ClientInit` respectively.

**Important:** The `script.Parent.Services.*` and `script.Parent.Controllers.*` references in the init files depend on the folder structure being synced correctly via Rojo's `default.project.json`. Make sure the project file maps directories properly.

## Files That Do NOT Need Changes
All other `.lua` files are ModuleScripts and are correctly named:
- `ServerScriptService/Services/*.lua` -- required by ServerInit
- `ServerScriptService/RemoteHandlers/*.lua` -- required by ServerInit
- `StarterPlayerScripts/Controllers/*.lua` -- required by ClientInit
- `StarterPlayerScripts/ViewModels/*.lua` -- required by ClientInit
- `ReplicatedStorage/Shared/**/*.lua` -- required by both sides
