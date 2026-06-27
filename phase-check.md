---
description: Verify the current build phase's Definition of Done before advancing
agent: build
---

Read `docs/SPEC.md` and identify which build phase we are currently on based on the state of the codebase.

Then do the following, in order:

1. State the current phase number and its Definition of Done verbatim from the SPEC.
2. Inspect the codebase and check each criterion in that Definition of Done. For anything you cannot verify by reading code, say what command the developer should run to confirm it (e.g. `docker-compose up`, `pytest`, build the iOS scheme).
3. Give a clear verdict: **PASS** (every criterion met) or **NOT YET** (list what's missing).
4. If PASS: state the next phase and its first task, then STOP and wait for the developer to tell you to begin. Do not start the next phase automatically.
5. If NOT YET: propose the smallest set of changes to close the gap, and ask before making them.

Do not skip ahead. Do not assume a criterion is met without evidence.

$ARGUMENTS
