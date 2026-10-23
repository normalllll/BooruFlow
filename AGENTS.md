# Repository instructions

General engineering, UI, and Flutter/Riverpod conventions live in the global
`~/.codex/AGENTS.md`. This file adds what is specific to BooruFlow.

## frost_ui

- frost_ui (`V:/Code/frost_ui`, branch `v0.2.0`) is the UI foundation. Adaptive, motion,
  material, and layout behavior belongs in its components; change it there when
  a page needs different shared behavior, and keep BooruFlow pages as
  compositions of those components.
- An app-side escape from frost_ui starts with a `frost-escape:` header naming
  the user approval and its boundary.

## Validation and commits

- By default, run static analysis, formatting checks, and diff checks appropriate
  to the change. Code generation runs as needed; tests and application builds run
  only when explicitly requested. At handoff, list the checks that ran; name an
  unrun check only if it blocks acceptance.
- Keep unpushed commits in a linear history; rebase rather than merge when
  reconciling them.

## Flutter UI automation

- Use the installed `flutter-ui-automation` skill for Flutter screenshots,
  recordings and runtime interaction. Read its SKILL.md and follow
  [the project harness](tool/automation/README.md).
- Use a dedicated background test instance, internal Driver events and scoped
  HWND capture. Preserve the user's foreground window, mouse and keyboard.
- Keep native presentation-fence failures explicit. Do not silently fall back
  to Computer Use, lower-fidelity media or application PNGs as native evidence.
- When a prerequisite or backend is missing, complete the authorized setup, or
  report what is missing and stop that workflow.
