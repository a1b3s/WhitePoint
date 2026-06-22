# AGENTS.md

## Shared Workspace

Use this repository as the shared working copy for Codex, Claude, and Gemini Antigravity.

- Canonical local checkout: `/Users/absnsk/Documents/Codex/WhitePoint`
- GitHub remote: `https://github.com/a1b3s/WhitePoint.git`
- Default branch: `main`

Do not create a second clone for the same work unless the user explicitly asks for an isolated branch or experiment.

## Git Rules

- Check `git status --short --branch` before editing.
- Keep user-made changes; do not reset, checkout, or delete them without explicit approval.
- Prefer small commits with clear messages.
- Fetch before assuming the remote is current.
- Do not print tokens, credentials, keychain contents, or environment secrets.

## Review Priorities

1. Security issues
2. Broken behavior
3. Data loss risk
4. Missing error handling
5. Maintainability problems
6. UI/UX regressions

## Scope

Make minimal, practical changes that match the task. Avoid unrelated refactors.
