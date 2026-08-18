# Contributing

Thanks for considering a contribution to this project.

## Workflow

This repo uses the [OpenSpec](https://github.com/Fission-AI/OpenSpec) spec-driven workflow. Changes are proposed and planned before code is written, using the `/opsx:*` commands in Claude Code (see [README.md](README.md#workflow) for the full command list).

1. **Propose** — run `/opsx:propose` to describe what you want to build. This generates a change proposal with design notes and tasks under `openspec/changes/`.
2. **Discuss** — open a pull request with the proposal so it can be reviewed before implementation starts, or discuss directly if working solo.
3. **Implement** — run `/opsx:apply` to work through the change's tasks.
4. **Archive** — once merged, run `/opsx:archive` to sync the change's specs into `openspec/specs/` and archive it.

If you're not using Claude Code, you can still edit files under `openspec/changes/` by hand following the existing structure.

## Getting started

See [README.md](README.md#setup) for setup instructions.

## Making changes

1. Fork the repo and create a branch from `main`.
2. Keep changes focused — one proposal/change per pull request where possible.
3. Follow the existing structure and style in `openspec/` and `.claude/`.
4. Write clear commit messages describing *why* a change was made, not just what changed.

## Pull requests

- Reference the related `openspec/changes/` proposal if one exists.
- Describe what changed and why in the PR description.
- Be responsive to review feedback — small, iterative commits are easier to review than large rewrites.

## Reporting issues

Open a GitHub issue with a clear description of the problem, steps to reproduce (if applicable), and expected vs. actual behavior.
