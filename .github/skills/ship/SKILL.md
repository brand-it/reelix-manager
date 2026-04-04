---
name: ship
description: Commit staged changes, push to GitHub, create a PR, and write the PR description. Use this when asked to ship, push, open a PR, or create a pull request from staged changes.
---

When asked to ship or create a PR from staged changes, follow this process exactly.

## Step 1 — Inspect the staged changes

Run both commands to understand what is staged:

```bash
git --no-pager diff --cached --stat
git --no-pager diff --cached
```

If nothing is staged, tell the user and stop.

## Step 2 — Run the tests

Verify the code is in a working state before doing anything else:

```bash
bin/rails test
```

If tests fail, stop and report the failures. Do not proceed.

## Step 3 — Generate and apply the commit message

Using the staged diff, determine the conventional commit type and compose a message following these rules:

- Format: `<type>(<optional scope>): <short imperative summary ≤ 72 chars>`
- Follow each with a blank line and bullet points explaining what changed and why
- Types: `feat`, `fix`, `refactor`, `test`, `chore`, `docs`, `perf`, `ci`, `style`
- Imperative mood ("add", "fix" — not "added" or "adds")
- No trailing period on the subject line
- Do NOT include a `Co-authored-by` trailer

Then commit immediately — no confirmation needed since the user explicitly invoked this skill:

```bash
git commit -m "<subject line>" -m "<bullet points as body>"
```

## Step 4 — Determine the target branch and push

Check the current branch and push it:

```bash
git --no-pager branch --show-current
git push -u origin HEAD
```

If the push fails, report the error and stop.

## Step 5 — Create the pull request

Use the commit subject line as the PR title. Create the PR against the default branch (`main`):

```bash
gh pr create --title "<commit subject>" --body "" --base main
```

Capture the PR URL from the output.

## Step 6 — Write and update the PR description

Based on the staged diff and commit, write a PR description using this structure:

```markdown
## Summary

<1–3 sentence explanation of what this PR does and why.>

## Changes

- <group of related changes and their purpose>
- <another group>

## Notes

<Any important implementation details, caveats, or things the reviewer should know. Omit this section if there is nothing notable.>
```

Then update the PR with the description:

```bash
gh pr edit --body "<the description>"
```

## Step 7 — Post the PR link

Retrieve the PR URL and present it clearly to the user:

```bash
gh pr view --json url --jq '.url'
```

Output it as the final message in this format:

```
✅ PR ready: <url>
```
