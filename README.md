# openspec-sf

An [OpenSpec](https://github.com/Fission-AI/OpenSpec) spec-driven project, set up for use with Claude Code.

## What is this?

OpenSpec is a workflow for planning and tracking changes as specs before code is written. Each change lives under `openspec/changes/` as a proposal with design notes and tasks; once implemented, it's synced into `openspec/specs/` and archived.

## Project structure

```
.claude/
  commands/opsx/   # /opsx:* slash commands (propose, explore, apply, sync, archive, update)
  skills/          # Matching OpenSpec skills used by Claude Code
openspec/
  config.yaml      # Project context and per-artifact/operation rules
  changes/         # Active and archived change proposals
  specs/           # Synced, current specs
```

## Setup

1. **Clone the repo**

   ```bash
   git clone https://github.com/wasimatiq/openspec-sf.git
   cd openspec-sf
   ```

2. **Open in Claude Code**

   The `.claude/` directory already provides the `/opsx:*` commands and skills — no extra install step is required. Just launch Claude Code in this directory.

3. **(Optional) Add project context**

   Edit `openspec/config.yaml` to describe your tech stack, conventions, and any per-artifact or per-operation rules. This context is shown to Claude when generating proposals, specs, and tasks.

## Workflow

| Command | Purpose |
|---|---|
| `/opsx:explore` | Think through an idea or problem before proposing a change |
| `/opsx:propose` | Describe what you want to build and generate a full proposal (design, specs, tasks) |
| `/opsx:apply` | Implement the tasks from an active change |
| `/opsx:sync` | Sync a change's delta specs into the main specs without archiving |
| `/opsx:archive` | Archive a change once implementation is complete |
| `/opsx:update` | Revise an existing change's planning artifacts |

Typical flow: `/opsx:propose` → `/opsx:apply` → `/opsx:archive`.
