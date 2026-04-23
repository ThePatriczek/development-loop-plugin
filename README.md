# thepatriczek-plugins

Personal Claude Code plugin marketplace by [@ThePatriczek](https://github.com/ThePatriczek).

## Plugins

### [development-loop](./plugins/development-loop)

Strict, ten-phase, hook-enforced development loop:

```
RESEARCH → RESEARCH-REVIEW
         → TDD-RED → TDD-GREEN → TDD-REVIEW
         → IMPLEMENTATION → IMPLEMENTATION-REVIEW
         → REFACTOR → REFACTOR-REVIEW
         → OVERALL-REVIEW
         → LOOP or DONE
```

- **10 skills** — one per phase + orchestrator.
- **9 agents** — one per phase, each strictly loads its phase skill as its authoritative contract.
- **4 hooks** — SessionStart (status banner) + three agent-type hooks (UserPromptSubmit, PreToolUse Write/Edit/MultiEdit, Stop).
- **Deep overall-review** — context-detected static analysis, security checklist, clean-code audit, Playwright MCP E2E when available.

See [`plugins/development-loop/README.md`](./plugins/development-loop/README.md) for usage.

## Install

Add this marketplace to your Claude Code:

```
/plugin marketplace add ThePatriczek/development-loop-plugin
```

Then install the plugin:

```
/plugin install development-loop@thepatriczek-plugins
```

Activate without restart:

```
/reload-plugins
```

## Using the plugin

Inside any repository you want to work on:

```
/development-loop start "Your concrete, one-sentence goal"
```

The orchestrator creates a state file at `.claude/development-loop.local.md` in that repo, enters the `research` phase, and from that moment on the hooks enforce the loop. Outside an active loop, zero overhead.

## License

MIT.
