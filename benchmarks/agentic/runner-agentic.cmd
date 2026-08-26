@echo off
"%~dp0../node_modules/.bin/opencode.cmd" run --agent build --format json -m %BE_MODEL% -f "%BE_TICKET_FILE%" -- "Complete the ticket in the attached file. Search the codebase first, then edit the repo in place. Keep the diff minimal." 1>"%BE_OUT%" 2>"%BE_ERR%"
