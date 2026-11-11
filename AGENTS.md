# Repository instructions

BooruFlow builds on frost_ui, which is expected in a sibling checkout at
`../frost_ui`.

## frost_ui

- Treat the frost_ui and frost_window sources, tests and tools as read-only.
  Follow `../frost_ui/docs/APP_WORKFLOW.md` for pacing, tests, running the app
  and screenshots. Request Frost changes through
  `../frost_ui/docs/requests/README.md`.
- Widgets the app paints or lays out itself live in `lib/ui/custom/` and start
  with `// app-owned: <feature>`. Use `// frost-escape: <request ID>` only for
  other exceptions the owner has approved.

## Tests and UI automation

- Run the tests affected by a change with
  `dart ../frost_ui/tool/affected_tests.dart <base> --repo . --run`.
- `tool/automation_entry.dart` is the Debug entrypoint for the flutter-ui-automation
  skill; add missing hooks there, not to `lib/main.dart`. It runs on the sample
  data of `tool/sample_main.dart` in an isolated profile.

## Commits

- Do not add AI attribution to commit messages or pull request descriptions.

## Project documentation

- [DEVELOPMENT.md](DEVELOPMENT.md) covers the toolchain, dependencies and
  checks; [tool/README.md](tool/README.md) the bridge, icon and branding tools.
