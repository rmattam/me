---
name: publish-pull-request
description: 'Commit reviewed repository changes, push the current Git branch, and create or find a GitHub pull request through the REST API without GitHub CLI, browser automation, or Playwright. Use when asked to commit, push, publish a branch, open a PR, or share a pull request link.'
argument-hint: '<commit message and optional PR title>'
---

# Publish Pull Request

Use this workflow to publish completed work and return a verified GitHub pull request URL without opening a browser.

## Safety Requirements

- Never print, log, persist, or pass a credential in a command argument.
- Never commit directly to the repository's default branch.
- Never stage files until all tracked changes and complete untracked-file contents have been reviewed.
- Scan changed, staged, and untracked files for passwords, private keys, access tokens, API secrets, connection strings, session cookies, and private certificates.
- If a secret is found, stop. Remove it from the pending change without displaying it and tell the user to revoke or rotate it.
- Preserve unrelated user changes. Stage only the exact reviewed paths intended for the pull request.
- Do not use Playwright or browser tools to create or verify the pull request. Use the bundled GitHub REST helper.

## Workflow

1. Inspect `git status --short`, the current branch, its upstream, configured remotes, the default remote branch, and the complete diff including untracked files.
2. Confirm the current branch is not the default branch. If it is, create a descriptive feature branch before committing.
3. Run repository-specific tests plus `git diff --check` and the secret scan required above.
4. Stage only the reviewed paths. Compare `git diff --cached --name-only` with the approved path list before committing.
5. Commit once with a concise imperative message. Do not amend an existing commit unless the user explicitly asks.
6. Push with upstream tracking: `git push --set-upstream <remote> <branch>`.
7. Build a concise PR title and Markdown body containing `Summary` and `Validation` sections.
8. Run [New-GitHubPullRequest.ps1](./scripts/New-GitHubPullRequest.ps1):

   ```powershell
   & ".github/skills/publish-pull-request/scripts/New-GitHubPullRequest.ps1" `
     -Title "Concise pull request title" `
     -Body ($bodyLines -join [Environment]::NewLine) `
     -Base "master"
   ```

9. Return the script's `Url`. It queries open pull requests first and returns an existing match instead of creating a duplicate.
10. Confirm `git status --short` is clean and report the commit SHA, branch, and pull request URL.

## Authentication

The helper obtains the existing `github.com` HTTPS credential through Git Credential Manager with interaction disabled. It keeps the credential in memory, uses it only in an authorization header, clears references in `finally`, and never emits it.

If no credential is available or GitHub returns `401` or `403`, stop and ask the user to authenticate Git Credential Manager. Do not fall back to Playwright, scrape a browser session, request a token in chat, or write a token to disk.

## Parameters

- `Title` is required.
- `Body` is optional Markdown.
- `Base` defaults to the remote's configured default branch.
- `Head` defaults to the current local branch.
- `Remote` defaults to `origin`.

The helper supports GitHub HTTPS and SSH remote URL formats and only creates pull requests within the remote repository.