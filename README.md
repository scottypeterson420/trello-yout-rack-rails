# Trello to YouTrack import tools

How to use it:

- Use environment variables for configuration. See `.env.sample`.
- `fetch` — fetch Trello and YouTrack API data.
- `map` — generate draft mapping to be used for Trello cards preprocessing:
  - Trello member to YouTrack user
  - Trello board to YouTrack project
  - Trello label (board-scoped) to YouTrack label (global)
- `push_labels` — generate YouTrack labels from the mapping (idempotent)
- `pull_cards` — download all Trello cards and map locally to YouTrack issues
- `push_issues` — push mapped issues to YouTrack
