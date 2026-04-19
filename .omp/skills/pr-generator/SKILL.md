---
id: pr-generator
description: Generate a pull request with a conventional commit-style title and structured description from the current branch. Use this when asked to generate a PR, create a pull request, or open a PR.
---

When asked to generate or create a pull request, follow this process exactly.

## Step 1 — Check for errors

Before creating a PR, verify the codebase is in a healthy state. Run these checks in order:

**1. Test errors:**
```bash
bin/rails test
```

**2. Type errors:**
```bash
bin/rails type_check:check
```

**3. Linter errors:**
```bash
bin/rubocop
```

**If any errors are found:**

- Stop immediately — do not continue with PR creation
- Use the `ask` tool to present the errors to the user
- Ask how they want to proceed with options like:
  1. Fix the errors before creating the PR (recommended)
  2. Create the PR anyway despite the errors
  3. Ignore specific error types and proceed
- Wait for user response before continuing

**If no errors are found:**

- Continue to the next step

## Step 2 — Check the current branch

```bash
git --no-pager branch --show-current
```

Note whether the current branch is `main` or `master` — if it is, a new feature branch must be created before the PR can be opened. Do **not** stop; continue to the next steps.

## Step 3 — Ask which base branch to target

Ask the user which branch this PR should be merged into. Offer `main` as the default alongside any other branches present in the remote.

```bash
git --no-pager branch -r --format="%(refname:short)" | sed 's|origin/||' | grep -v HEAD | sort
```

Present the list to the user and ask them to pick a base branch (default: `main`). Remember this choice — it is used as `<base>` in every `git` and `gh` command below.

## Step 4 — Inspect what has changed

Gather context from two sources using the chosen base branch:

**Commits ahead of base:**
```bash
git --no-pager log origin/<base>..HEAD --oneline
git --no-pager log origin/<base>..HEAD --format="%B"
```

**Diff from base:**
```bash
git --no-pager diff origin/<base>...HEAD --stat
git --no-pager diff origin/<base>...HEAD
```

If there are no commits and no staged changes ahead of the base branch, tell the user and stop.

## Step 5 — Determine the PR type and scope

Choose the type that best describes the primary nature of the changes:

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

The optional scope should be the main area of the codebase affected (e.g. `auth`, `uploads`, `config`, `graphql`).

## Step 6 — Compose the PR title

Use this format:

```
<type>(<optional scope>): <short imperative summary ≤ 72 chars>
```

Rules:
- Imperative mood: "add", "fix", "replace" — not "added" or "adds"
- No trailing period
- ≤ 72 characters total

## Step 7 — Create a feature branch if needed

If the current branch is `main` or `master`, a feature branch must be created before pushing.

Derive a branch name from the PR title using these rules:
- Start with the conventional commit type (and scope if present): `feat/`, `fix/`, `chore/`, etc.
- Convert the short summary to lowercase, replace spaces and special characters with hyphens, strip trailing hyphens
- Keep it under 50 characters total
- Example: `feat(auth): add TMDB API key rotation` → `feat/add-tmdb-api-key-rotation`

Suggest the generated name to the user and ask them to confirm or provide a different name. Then create and switch to the branch:

```bash
git checkout -b <branch-name>
```

If the user is already on a non-`main` feature branch, skip this step entirely — do not rename or recreate the branch.

## Step 8 — Write the PR description

Use this structure:

```markdown
## Summary

<1–3 sentences explaining what this PR does and why. Focus on the intent, not the implementation details.>

## Changes

- <group of related changes and their purpose>
- <another group>
- <...>

## Notes

<Any important implementation details, caveats, or things the reviewer should pay attention to. Omit this section entirely if there is nothing notable.>
```

Rules:
- Group related file changes into a single bullet — do not list every file individually
- Describe *what* changed and *why*, not *how*
- Keep each bullet to one sentence

## Step 9 — Present the title and description

Show the user the generated title and description. Then ask if they would like you to:

1. Push the branch and create the PR
2. Just show the title and description (copy/paste)

If they confirm option 1, run:

```bash
git push -u origin HEAD
gh pr create --title "<title>" --body "<description>" --base <base>
```

Then retrieve and display the PR URL:

```bash
gh pr view --json url --jq '.url'
```

Output it as the final message:

```
✅ PR ready: <url>
```
