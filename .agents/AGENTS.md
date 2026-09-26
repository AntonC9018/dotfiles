## Git identity

**Git identity:** never override git identity (no `-c user.name/email`, no `GIT_AUTHOR_*`/`GIT_COMMITTER_*` env); commits must use the repo's configured identity; model attribution goes ONLY in the `Generated-by:` trailer.

## Commit attribution

When you write code/docs and create a commit, append trailer `Generated-by: <model-id>` to the commit message body (blank line + trailer at end). Use `git commit --trailer "Generated-by: <id>"` or `git interpret-trailers --trailer`. Trailers are required for GitHub visibility. Git notes (`git notes add -m "model: <id>" HEAD`) are an optional supplement only.
The `Generated-by:` trailer applies ONLY when the commit contains model-authored code/files. Do NOT add it to pure-message commits, overviews, beads bookkeeping syncs, or commits with no model-authored content.
Never override git identity (`-c user.name/email`, `GIT_AUTHOR_*`/`GIT_COMMITTER_*`); model attribution goes only in the trailer.

Example (model-authored code):
  Fix typo in README

  Generated-by: my-model-id

Example (no trailer — bookkeeping only):
  Beads: sync interactions log

## Prototype previews

When doing prototypes, follow guidance in `prototypes.md` next to this file (`~/.agents/prototypes.md`; on Windows `%USERPROFILE%\.agents\prototypes.md`).
