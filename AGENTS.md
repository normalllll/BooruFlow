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

## Commit content

- Code, test names, file names and commit messages describe the code, never
  the plan, review or conversation that produced it. Specs, plans and handoff
  notes stay in the ignored `docs/` folder or in `../frost_ui/docs/`; do not
  commit, quote or link them.
- `// app-owned: <feature>` and `// frost-escape: <request ID>` are the only
  places where a feature tag or request ID may appear.
- A fix to a commit that is not on `origin/main` yet goes into that commit with
  `git commit --fixup`. Pushed history is linear.
- Enable the hooks once per clone with `git config core.hooksPath tool/hooks`.
  They run `dart tool/check_history.dart` on each commit and push. Never pass
  `--no-verify`; if the check flags correct text, stop and report it.

## Commits

- Do not add AI attribution to commit messages or pull request descriptions.

## Project documentation

- [DEVELOPMENT.md](DEVELOPMENT.md) covers the toolchain, dependencies and
  checks; [tool/README.md](tool/README.md) the bridge, icon and branding tools.
