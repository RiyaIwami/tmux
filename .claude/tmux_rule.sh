#!/bin/bash

INPUT=$(cat)

STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

if [[ "$CLAUDE_IS_SUBAGENT" == "true" ]]; then
    exit 0
fi

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    exit 0
fi

PANE_NAME=$(tmux display-message -p "#{pane_id}" 2>/dev/null)

if [ "$PANE_NAME" = "%1" ]; then
    HEADER="以下のtmuxコマンドの'タスク内容'を現在のタスクに編集し、マネージャーにtmux経由で報告して下さい"
    MESSAGE="tmux send-keys -t 0 "'タスク内容'が完了しました。次の指示を与えて下さい" && sleep 0.2 && tmux send-keys -t 0 Enter"

    FULL_MESSAGE="$HEADER"$'\n'"$MESSAGE"
    ESCAPED_REASON=$(jq -Rs . <<< "$FULL_MESSAGE")

    cat <<EOF
{
    "decision": "block",
    "reason": $ESCAPED_REASON
}
EOF

fi
