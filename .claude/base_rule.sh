#!/bin/bash

INPUT=$(cat)

if [[ "$CLAUDE_IS_SUBAGENT" == "true" ]]; then
    exit 0
fi

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
    exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

MESSAGES=()

if [[ "$FILE_PATH" =~ \.php$ || "$FILE_PATH" =~ \.blade\.php$ ]]; then
    MESSAGES+=(" ./docs/CODING_STANDARDS.md に準拠しているか確認実行")
    MESSAGES+=(" ./docs/SECURITY_GUIDE.md に準拠しているか確認実行")
fi

if [[ "$FILE_PATH" =~ ^Controller/[^/]+\.php$ || "$FILE_PATH" =~ ^Requests/[^/]+\.php$ ]]; then
    MESSAGES+=(" ./docs/CONTROLLER_GUIDE.md に準拠しているか確認実行")
fi

if [[ "$FILE_PATH" =~ \.blade\.php$ ]]; then
    MESSAGES+=(" ./docs/VIEW_GUIDE.md に準拠しているか確認実行")
fi

if [[ "$FILE_PATH" =~ ^Models/[^/]+\.php$ || "$FILE_PATH" =~ ^database/[^/]+\.php$ ]]; then
    MESSAGES+=(" ./docs/MODEL_GUIDE.md に準拠しているか確認実行")
    MESSAGES+=(" ./docs/TABLE_GUIDE.md に準拠しているか確認実行")
fi

if [[ "$FILE_PATH" =~ ^routes/[^/]+\.php$ ]]; then
    MESSAGES+=(" ./docs/ROUTING_GUIDE.md に準拠しているか確認実行")
fi

if [ ${#MESSAGES[@]} -gt 0 ]; then
    HEADER="以下の手順に沿ってタスクを実行してください。"

    FORMATTED=$(for i in "${!MESSAGES[@]}"; do
        INDEX=$((i + 1))
        echo "$INDEX. ${MESSAGES[$i]}"
    done)

    FULL_MESSAGE="$HEADER"$'\n'"$FORMATTED"
    ESCAPED_REASON=$(jq -Rs . <<< "$FULL_MESSAGE")

    cat <<EOF
{
    "decision": "block",
    "reason": $ESCAPED_REASON
}
EOF

    exit 0
fi

exit 0
