
## Sharing files with the user in T3 Code (verified 2026-10-05)

T3 Code chat is NOT a browser: only `http(s)` URLs are clickable links.
Everything below was established empirically in-session
(UNC, `file://`, and relative markdown links all render dead). Prefer these mechanisms:

- Images: embed inline with markdown + absolute Linux path.
  Example: `![clean probe end frame](/tmp/anim-glitch-probes/frames/clean-end-4p0.png)` renders the image in chat.
- Videos: same syntax with an `.mp4` absolute path renders a playable video player.
  Example: `![displaced probe video](/tmp/anim-glitch-probes/output/displaced--CourseAnimation.mp4)` (4 s, plays in chat).
- Clickable file refs: put the path in backticks.
  Example: `/home/anton/coding/course_management-anim-glitch/research/animation-glitch-probes.md` opens on click —
  BUT only for files inside the current workspace. Absolute paths outside it fail with
  `Failed to read workspace file 'X' in '<workspace>'`.
- Folders NEVER open by click (trailing slash or not — they are attempted as a file read and fail).
  For folders, tell the user to right-click → Open In Explorer, which works for files and folders alike.
- To point at a set of videos/files, link an index file instead (e.g. `/tmp/anim-glitch-probes/GROUND_TRUTH.md`).

## Commit attribution

Add a `Generated-by:` trailer to each commit authored by you
and specify your model, like `GPT 6.1 Sol`, or whatever your model is.

Do this if you commit docs or code that were authored by you (or by subagents).
If you just committed on user's request without your code in the commit, don't include it.

Never override git identity (`-c user.name/email`, `GIT_AUTHOR_*`/`GIT_COMMITTER_*`); 
model attribution goes only in the trailer.

Make commits from `anton-agent-9018` account.
Push from the default user.

## Serving frontends

Follow guidance in `prototypes.md` next to this file (`~/.agents/prototypes.md`;
on Windows `%USERPROFILE%\.agents\prototypes.md`).

## Subagents

If a repository is public, and no private data is going to be touched by a subagent,
you should use free subagents via OpenCode.

Ask the user if you're allowed to use free OpenCode subagents for private repos 
and for tasks that might involve looking at private data.
The free models are preffered over alternatives.
Authorization or denial can come from an `AGENTS.md`.

Note that the free models are generally less intelligent than the frontier models,
so try to use them for cheap tasks like scanning the codebase for certain patterns,
reading a lot of text, or writing code that is not too complex.

Always specify the effort of the free models. 
Default to medium for mechanical tasks, and to the maximum advertised level for coding.

The preferred models are Muse Spark 1.3 Free and Space Bunny.

Do not call paid models via OpenCode, unless explicitly asked to by the user.

If free models are off limits, use GPT 6 Luna instead.

Keep using more intelligent models for deep code review and other tasks that need it.
For GPT 6.1 Sol, use high effort for code review.
Do not use GPT 6 Astra, unless explicitly asked.

Ask the user to select the effort level if you're not sure.

