# Code host reference

Implementation issues go to each component's repo (config, "Components"). GitHub through `gh` comes first; GitLab through `glab` is the second option. An MCP server for either can replace the CLI if it's connected and can write issues.

## Auth (no pre-check)

Run the first call the step needs (step 2's search, or step 6's create).

**GitHub (`gh`):**

1. It works: use plain `gh` from then on.
2. It fails with "Could not resolve to a Repository" (or 404): the active account can't see the repo. Run `gh auth status` to list logged-in accounts and pick one that can.
3. Prefix every `gh` call with `GH_TOKEN=$(gh auth token -u <that account>)`. Never `gh auth switch`: it changes the user's global state.
4. No account has access: pause (SKILL.md, "When a tool is unusable") and ask the user to `gh auth login`. Other causes worth naming: SSO authorization for the org, or a token missing the `repo` scope.

**GitLab (`glab`):**

1. Run `glab auth status` if the first call fails. For a self-hosted instance, pass `--hostname` or set `GITLAB_HOST`.
2. A different account works through `GITLAB_TOKEN=<token from the user's env var>` for that one call. Never rewrite the user's glab config.
3. No access: pause and ask the user to `glab auth login`.

## Passing the body (no files)

Drafts live only in chat. The draft's `# <title>` line becomes the title; the rest is the body, passed through a **quoted** heredoc so backticks, `$` and mermaid stay literal.

## Commands

```bash
# GitHub
gh issue list -R <owner/repo> --state all --search "<parent id> in:body" --json number,title,url   # existing issues (step 2)
gh issue create -R <owner/repo> --title "<title>" --label <label> --body-file - <<'BODY'
<body from the approved draft>
BODY
gh issue edit <n> -R <owner/repo> --body-file - <<'BODY'
<updated body>
BODY
gh issue view <n> -R <owner/repo> --json title,body,labels,url                                     # read back

# GitLab
glab issue list -R <group/project> --search "<parent id>" --all
glab issue create -R <group/project> --title "<title>" --label <label> --description "$(cat <<'BODY'
<body from the approved draft>
BODY
)"
glab issue update <n> -R <group/project> --description "$(cat <<'BODY'
<updated body>
BODY
)"
glab issue view <n> -R <group/project>                                                              # read back
```

`glab` flags change between versions: if one is rejected, check `glab issue <cmd> --help` rather than guessing.

**Verified** means the read-back body starts with the parent link line and contains every section heading.

Labels are set with the flag (from config), never written into the body. Mermaid renders on both GitHub and GitLab.
