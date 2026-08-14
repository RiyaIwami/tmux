#! /usr/bin/env node

import { execFileSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import path from "node:path";
import os from "node:os";

try {
    const input = JSON.parse(readFileSync(process.stdin.fd, 'utf8'));
    if (!input.transcript_path) {
        process.exit(0);
    }

    const homeDir = os.homedir();
    let transcriptPath = input.transcript_path;

    if (transcriptPath.startsWith('~/')) {
        transcriptPath = path.join(homeDir, transcriptPath.slice(2));
    }

    const allowedBase = path.join(homeDir, '.claude', 'projects');
    const resolvedPath = path.resolve(transcriptPath);

    if (!resolvedPath.startsWith(allowedBase)) {
        process.exit(1);
    }

    if (!existsSync(resolvedPath)) {
        console.log('フック実行失敗: トランスクリプトファイルが存在しません');
        process.exit(0);
    }

    const lines = readFileSync(resolvedPath, "utf-8").split("\n").filter(line => line.trim());
    if (lines.length === 0) {
        console.log('フック実行失敗: トランスクリプトファイルが空です');
        process.exit(0);
    }

    const lastLine = lines[lines.length - 1];
    const transcript = JSON.parse(lastLine);
    const lastMessageContent = transcript?.message?.content?.[0]?.text;

    if (lastMessageContent) {
        const script = `
          on run {notificationTitle, notificationMessage}
            try
              display notification notificationMessage with title notificationTitle
            end try
          end run
        `;
        execFileSync('osascript', ['-e', script, "Claude Code", lastMessageContent], {
            stdio: 'ignore'
        });
    }
} catch (error) {
    console.log('フック実行失敗:', error.message);
    process.exit(1);
}