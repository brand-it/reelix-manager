---
id: commit-message-generator
description: Generate a conventional commit message from staged git changes. Use this when asked to write, create, or generate a commit message from staged changes or the git diff.
---

When asked to generate a commit message from staged changes, follow this process:

## Step 1 — Inspect the staged diff

Run both of these commands to understand what is staged:

```bash
git --no-pager diff --cached --stat
git --no-pager diff --cached
```

If there is nothing staged, tell the user and stop.

## Step 2 — Run the build and tests

Before composing the commit message, verify the code is in a working state by running the test suite:

```bash
bin/rails test
```

If the tests fail, stop and report the failures to the user. Do not proceed with the commit until the tests pass.

## Step 3 — Determine the commit type

Choose one of these Conventional Commits types based on the primary nature of the changes:

| Type       | When to use                                                          |
|------------|----------------------------------------------------------------------|
| `feat`     | A new feature or capability                                          |
| `fix`      | A bug fix                                                            |
| `refactor` | Code restructuring with no behaviour change                          |
| `test`     | Adding or updating tests only                                        |
| `chore`    | Dependency updates, build config, tooling                            |
| `docs`     | Documentation only                                                   |
| `perf`     | Performance improvement                                              |
| `ci`       | CI/CD configuration changes                                          |
| `style`    | Formatting, whitespace — no logic change                             |

## Step 4 — Compose the message

Use this structure:

```
<type>(<optional scope>): <short imperative summary under 72 chars>

- <bullet summarising one logical group of changes>
- <bullet summarising another group>
- ...
```

Rules:
- Subject line: imperative mood ("add", "replace", "fix" — not "added" or "adds")
- Subject line: no trailing period
- Subject line: ≤ 72 characters
- Bullet points: describe *what* changed and *why*, not *how*
- Group related file changes into a single bullet
- Do NOT include a `Co-authored-by` trailer

## Step 5 — Present and optionally commit

Show the user the generated message. Then ask if they would like you to run:

```bash
git commit -m "<the generated message>"
```

Do not run `git commit` without explicit confirmation.

