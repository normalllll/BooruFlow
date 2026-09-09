# Repository instructions

Apply these conventions throughout the repository. Use technology-specific rules
where that technology is in use. Follow explicit task instructions for scope and
validation.

## Organization and responsibilities

- Organize code by business feature and keep related code close together.
- Introduce layers only when business complexity, reuse, or a concrete dependency
  boundary justifies them. Do not add layers for their own sake.
- Avoid overcrowded directories, unnecessary single-file directories, and deeply
  nested structures.

## Abstraction and data modeling

- Do not introduce extensive layering merely to adopt domain-driven design or
  mechanically apply an architecture pattern.
- Do not suffix every data model with `Dto`. Use that suffix only when a transport
  model needs to be distinguished from an internal model.
- Avoid wrappers, interfaces, and model conversions without a concrete benefit.

## Riverpod

- Declare providers and notifiers through annotations and code generation. Do not
  handwrite declarations that the generator can produce.
- Do not end notifier class names with `Controller`. Prefer default generated
  provider names.
- Name a directory's sole logic file `logic.dart`. When multiple logic files are
  justified, use meaningful names following `xx_logic.dart`.
- Choose provider retention according to the required lifecycle; do not enable
  keep-alive indiscriminately.

## State ownership

- Manage business and shared state consistently through the project's state
  management solution. Do not maintain the same business state through multiple
  competing mechanisms.
- Keep focus, text controllers, animation, scrolling, and temporary expansion
  state in the appropriate UI scope.
- Supply service dependencies through a consistent injection boundary. Avoid
  scattered UI access to mutable global singletons.

## Lifecycles and side effects

- Keep UI build and render paths free of business-state writes, network requests,
  and other side effects.
- Respect framework lifecycle restrictions. In Riverpod disposal, cancellation,
  and resume callbacks, do not synchronously access or mutate provider state.
- Guard deferred work against disposal and stale operations before it takes
  effect.
- Release subscriptions, timers, and controllers when their owning scope ends.

## Asynchronous and immutable state

- Prefer immutable state with explicit loading, success, and failure states.
- Handle request races, cancellation, and stale responses so older work cannot
  overwrite newer results.
- Preserve existing content during refresh and pagination when appropriate for
  the feature. Provide useful error feedback and retry behavior.

## Types and control flow

- Model states with explicit types. Avoid string conventions, `dynamic`, and
  combinations of boolean parameters when a clear data model is appropriate.
- Prefer Dart 3 control-flow syntax and features, including pattern matching,
  variable declaration patterns, if-case statements, switch expressions, and
  exhaustiveness checking. Use them to reduce repeated checks, casts, and
  temporary variables.
- Use ternary expressions for simple binary choices. Use clear control-flow
  statements for complex branches and side effects. Avoid nested ternaries and
  cryptic shorthand.

## Naming and formatting

- Follow language conventions and the project's formatter and static-analysis
  rules.
- Name symbols for their business meaning and responsibility. Avoid vague
  abbreviations, redundant prefixes or suffixes, and unnecessary intermediate
  variables.
- Do not hide problems by broadly disabling lint or analysis rules.

## Components and visual consistency

- Reuse existing components, themes, and design tokens.
- Unify repeated styles and interactions through appropriate component variants.
  Avoid copying near-identical implementations.
- Extract components when doing so improves reuse or readability. Preserve
  keyboard interaction, accessibility, and platform adaptation.

## Internationalization

- Manage user-facing text through the project's existing internationalization
  mechanism. Maintain supported languages when adding or changing text.
- Avoid scattered language checks and hardcoded translations in business code.
- Format dates, numbers, and similar values for the applicable locale.

## Module and platform boundaries

- Follow the project's actual responsibility boundaries and keep dependency
  directions clear between UI, business logic, data access, and platform code.
- Concentrate platform differences at appropriate boundaries.
- Keep types, error semantics, and resource lifecycles consistent across language
  and process interfaces.

## Generated code and tooling

- Edit source definitions and regenerate outputs with the project's prescribed
  tools. Do not hand-edit generated files.
- Obtain tool versions and options from project configuration.
- Include required generated outputs with source changes and avoid unrelated
  generated churn.
- Never add lock files to Git tracking, including by force-adding ignored files.
  Add matching rules to the appropriate `.gitignore` as soon as a lock file first
  appears, before staging any changes, and keep those rules in place.

## Refactoring and comments

- Split code according to responsibility, complexity, and maintainability, not a
  fixed line-count threshold alone.
- Do not introduce abstractions for hypothetical future requirements.
- Preserve existing behavior during refactoring, including caching, scroll
  restoration, retries, cancellation, and platform differences.
- Use comments to explain reasons, constraints, and non-obvious tradeoffs.

## Validation and commits

- By default, run static analysis, formatting checks, and diff checks appropriate
  to the change. Do not run tests or application builds unless explicitly
  requested. Code generation does not count as an application build. At handoff,
  state exactly which checks were run and what remains unverified.
- Organize commits around clear responsibilities. Fold follow-up corrections into
  the relevant commits when agreed, rather than fragmenting the same change.
- Keep unpushed commits in a linear history without merge commits. When history
  needs to be reconciled, rebase unpushed commits rather than creating a merge
  commit; preserve shared history.
- Do not push changes or rewrite shared history unless authorized.
