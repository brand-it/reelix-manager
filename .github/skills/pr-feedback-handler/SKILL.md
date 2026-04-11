---
name: pr-feedback-handler
description: Review pull request feedback, decide whether each thread needs a code change or an explanation, reply on GitHub, resolve the threads, and commit/push any required fixes.
---

When asked to handle pull request feedback, follow this process.

## Step 1 — Gather the PR feedback

Fetch the open review threads and review summaries for the target pull request.

Use the GitHub tools first when available. If you need thread node IDs for replying/resolving, query them with `gh api graphql`.

At minimum collect:
- thread resolution state
- comment body
- file path / line
- thread node id

## Step 2 — Inspect the current code

Read the files mentioned in the feedback before deciding what to do.

For each thread, classify it as one of:

1. **Fix now** — the review feedback is correct and should be addressed in code/tests/docs
2. **Explain only** — the current behavior is intentional or the thread is outdated, so reply with a concise explanation

Do not hand-wave. If you claim something is safe or already fixed, verify it in the code or with the relevant command.

## Step 3 — Implement any real fixes

If a thread needs a code change:

- make the smallest complete fix
- update tests/docs when the behavior contract changes
- run the relevant checks first, then the full suite required by the repo

Typical validation:

```bash
bin/rails test
bundle exec rake type_check
```

Run any extra tool that matches the feedback when relevant (for example `bin/brakeman -q` for security-tooling comments).

## Step 4 — Commit and push if code changed

If you changed code:

1. stage the intended files
2. generate a conventional commit message
3. commit
4. push the branch

Do not claim a thread is fixed until the branch contains the fix.

## Step 5 — Reply on each thread

For every open thread, leave a reply that does one of these:

- **Fixed** — summarize the change and mention the relevant behavior now covered
- **Not changing** — explain clearly why the current behavior is acceptable

Keep replies direct and specific to the thread.

## Step 6 — Resolve the thread

After replying, resolve the thread on GitHub.

You can do this with GraphQL mutations such as:

```graphql
mutation($threadId: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: { pullRequestReviewThreadId: $threadId, body: $body }) {
    comment { id }
  }
  resolveReviewThread(input: { threadId: $threadId }) {
    thread { isResolved }
  }
}
```

If GitHub CLI `gh pr edit/view` hits GraphQL scope issues, prefer `gh api` with REST/GraphQL endpoints directly.

## Step 7 — Report the outcome

Summarize:

- which threads were fixed in code
- which threads were resolved with explanation only
- the new commit SHA if a commit was created
- whether the branch was pushed

Do not stop after only making code changes locally; the task includes the GitHub thread follow-up.
