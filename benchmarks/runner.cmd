@echo off
cd /d "%~dp0"
".\node_modules\.bin\opencode.cmd" run --pure --agent oneshot --format json -m %BE_MODEL% "The attached file contains a coding task, optionally preceded by a ruleset that you must follow while completing it. Complete the task." -f "%BE_PROMPT_FILE%" 1>"%BE_OUT%" 2>"%BE_ERR%"
