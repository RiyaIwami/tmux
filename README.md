# tmux

## Mac　独自コマンド作成

1. ファイルを開き以下の３コマンドを登録
```shell
sudo vi ~/.zshrc
```
<br>

2. 権限付与した状態でClaude Codeを立ち上げるコマンド<br>
```shell
alias cc='claude --dangerously-skip-permissions'
```
<br>

3. tmuxのセッションを全削除するコマンド<br>
```shell
alias ccend='tmux kill-server'
```
<br>

4. tmuxを6窓で開き、角窓に権限付与した状態でClaude Codeを使用する<br>
```shell
alias ccmulti='tmux new-session -d -s ai-team -n manager \; set -g mouse on \; split-window -v \; select-pane -t 1 -T "reviewer" \; split-window -h -t 1 \; select-pane -t 2 -T "dev-a" \; split-window -h -t 2 \; select-pane -t 3 -T "dev-b" \; split-window -v -t 3 \; select-pane -t 4 -T "dev-c" \; split-window -v -t 4 \; select-pane -t 5 -T "tester" \; select-layout tiled \; send-keys -t 0 "cc" C-m \; send-keys -t 1 "cc" C-m \; send-keys -t 2 "cc" C-m \; send-keys -t 3 "cc" C-m \; send-keys -t 4 "cc" C-m \; send-keys -t 5 "cc" C-m \; attach-session -t ai-team'
```

## ドキュメント遵守義務化Hooks登録手順
1. `./.claude/`内に`base_rule.sh`を複製
2. `chmod +x ./.claude/base_rule.sh`でシェルスクリプトの実行権限を編集
3. Claude Codeを立ち上げ、`/hooks`コマンドを入力。
4. 立ち上がったhooksメニューで、`PostTooUse`を選択
5. `Add new matcher...`へ進む
6. Tool matcherに`Write|Edit|MultiEdit`と入力する
7. 確認画面に移るのでEnterで次へ進む
8. Commandに`./.claude/base_rule.sh`と入力する。
9. 適用範囲を設定する。Project settings`./.calude/settings.json`を選択
10. 登録が完了したので`/exit`コマンドを入力し、再度Claude Codeを立ち上げる
11. `/hooks`>`PostToolUse`内にコマンドが登録済みか確認する。

## Sub Agent
- 別のコンテキストを持ち、

## FigmaMCP連携
1. Figmaデスクトップアプリを立ち上げ、MCPサーバーを有効にする
   Figmaアイコン → 基本設定 → Dev Mode MCPサーバーを有効にする
2. Claude Codeを立ち上げるターミナルで以下のコマンドを実行
```shell
  claude mcp add --transport sse figma-dev-mode-mcp-server http://127.0.0.1:3845/sse
```
3. デザインしたページを選択 -> コピー/貼り付けオプション -> 選択範囲へのリンクをコピー
4. CLAUDE.mdなどに記載することで、Claude CodeがMCPを介してデザインを取得することが可能になる。

## パーミッションの設定
1. Claude Codeを立ち上げ、`/permissions`と入力する
2. `Allow`,`Deny`,`Workspace`の選択肢の中から`Deny`を選択
3. `Read(**/.env**)`を追加する
5. どこまでの適用範囲にするのか選択肢が与えられるので`User settings`を指定する。
6. 同じ手順で`Bash(rm -rf:*)`
これ
## トークン管理（/clear）

dev-aなどの部下ペインのトークンが増えてきた場合、managerから`/clear`を送信してコンテキストをリセットできる。

**実行タイミングの目安**
- タスク完了時（新しいタスクに集中させるため）
- トークン使用量が高くなってきたとき（`ccusage`で確認）
- エラーが頻発しているとき（コンテキストをリセット）
- 複雑な作業から単純な作業に切り替えるとき

**個別にクリア**
```shell
tmux send-keys -t %1 "/clear" && sleep 0.2 && tmux send-keys -t %1 Enter
```

**全ペイン一括クリア**
```shell
tmux send-keys -t %1 "/clear" && sleep 0.2 && tmux send-keys -t %1 Enter & \
tmux send-keys -t %2 "/clear" && sleep 0.2 && tmux send-keys -t %2 Enter & \
tmux send-keys -t %3 "/clear" && sleep 0.2 && tmux send-keys -t %3 Enter & \
wait
```

## ペイン状況確認

部下が応答しない・報告が来ない場合、managerから各ペインの画面内容を確認できる。

**個別確認**
```shell
tmux capture-pane -t %1 -p | tail -10
```

**全ペイン一括確認**
```shell
for pane in %1 %2 %3 %4 %5; do
    echo "=== $pane ==="
    tmux capture-pane -t $pane -p | tail -5
done
```

**確認が有効な場面**
- 部下が応答しない（フリーズ・エラー状態の確認）
- 報告内容の詳細確認（エラーメッセージの全文）
- 進捗の客観的な把握

## トークン使用量の確認

```shell
ccusage
```

使用量が多い部下ペインを特定して、優先的に`/clear`をかける目安にする。

<!-- ## 並列処理用変更共有スクリプト

1. ローカルにシェルスクリプトを作成する。
```shell
sudo vi ~/usr/local/bin/sync-log.sh
```
<br>

2. ファイル作成
```shell
#!/bin/bash
# sync-log.sh

SKIP_PANE=$1

tail -f ~/project/*/claude.log | while read -r line; do
  if [[ $line =~ "CREATED:" ]]; then
    for pane in 0 1 2 3 4 5; do
      if [[ "$pane" == "$SKIP_PANE" ]]; then
        continue
      fi
      tmux send-keys -t ai-team:0.$pane "New component created: $line"
      sleep 0.2
      tmux send-keys -t ai-team:0.$pane Enter
    done
  fi
done

```

3. .zshrcファイルを開く
```shell
sudo vi ~/.zshrc
```
<br>

4. エイリアス登録
```shell
alias ccsync="~/usr/local/bin/sync-log.sh"
```
<br> -->
