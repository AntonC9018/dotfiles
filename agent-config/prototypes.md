## Prototype previews

- Start every prototype preview with the user-level preview script, run from the project root:
  - Linux/macOS: `pwsh -File ~/.agents/scripts/start-prototype-preview.ps1 -PrototypePath 'prototypes/<name>.html' -QueryString '<key=value>'`
  - Windows: `pwsh -File "$env:USERPROFILE\.agents\scripts\start-prototype-preview.ps1" -PrototypePath 'prototypes/<name>.html' -QueryString '<key=value>'`
- Do not open or foreground the preview for the user. If visual verification is needed, keep browser automation in the background.
- Give the user the complete preview URL as plain text. Include the full path and query string. Do not shorten it or hide it behind a Markdown link label.
