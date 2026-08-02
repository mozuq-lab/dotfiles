# dotfiles

macOS をメイン環境とする個人設定ファイル集。Windows 用のセットアップ（`setup.bat`）も残してあるが、現在は未テスト。

## セットアップ

### macOS

```sh
git clone https://github.com/mozuq-lab/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh      # シンボリックリンクを作成（再実行可能）
brew bundle     # 依存ツールをインストール
```

git-secrets を初めて使うマシンでは、テンプレートも作成する：

```sh
git secrets --install ~/.git-templates/git-secrets
```

`setup.sh` は既存の `~/.zshrc` などを `~/.zshrc.dotfiles-backup` へ退避してからリンクに置き換える。
そのマシンだけで使う設定は `~/.zshrc.local`・`~/.zshenv.local` に書く（どちらも git 管理外）。

### Windows

`setup.bat` を管理者権限（または開発者モードを有効にした状態）で実行する。
**注意: 現在の setup.bat は Windows 実機で未テスト。** また `claude/settings.json` 内の
dart-lsp マーケットプレイスのパスは Mac の絶対パスなので手動調整が必要。

## 依存関係

| ツール | 用途 | 導入方法 |
|---|---|---|
| Vim 9+ | エディタ本体 | macOS 標準 |
| git, curl | セットアップ・vim-plug の自動取得 | macOS 標準 |
| jq | Claude Code のステータスライン | macOS 標準 |
| ripgrep | fzf.vim の `:Rg` 検索（`,g`） | `brew bundle` |
| git-secrets | AWS 認証情報の誤コミット防止 | `brew bundle` |
| tig | git TUI クライアント | `brew bundle` |
| Node.js | coc.nvim（LSP・補完）の実行環境 | nvm 等で別途導入 |
| fzf | あいまい検索本体 | vim-plug が自動インストール |

## Vim プラグイン管理（vim-plug）

プラグインは [vim-plug](https://github.com/junegunn/vim-plug) で管理している。
初回の Vim 起動時に plug.vim のダウンロードと `:PlugInstall` が自動実行される。

| コマンド | 動作 |
|---|---|
| `:PlugInstall` | `.vimrc` に書かれたプラグインをインストール |
| `:PlugUpdate` | プラグインを更新 |
| `:PlugClean` | `.vimrc` から消したプラグインを削除 |
| `:PlugUpgrade` | vim-plug 自体を更新 |
| `:PlugStatus` | インストール状態の確認 |

プラグインの追加は `.vimrc` の `plug#begin` 〜 `plug#end` の間に
`Plug 'owner/repo'` を書いて `:PlugInstall` を実行する。

LSP・補完・リントは coc.nvim に集約している。拡張は `g:coc_global_extensions`
に列挙したものが初回起動時に自動インストールされる。追加は `:CocInstall coc-xxx`。

### 主要キーマップ（Leader は `,`）

| キー | 動作 |
|---|---|
| `,f` / `,b` / `,g` | ファイル / バッファ / grep 検索（fzf） |
| `,e` / `,E` | ファイルツリー表示 / 現在ファイルの場所を表示 |
| `gd` / `gr` / `K` | 定義ジャンプ / 参照検索 / ドキュメント表示（coc） |
| `[g` / `]g` | 前後の診断へジャンプ |
| `,rn` / `,ca` | リネーム / コードアクション |
| `,o` | アウトライン表示（Vista） |
| `,q` | QuickRun |

## 構成メモ

- Vim の swap / backup / undo / viminfo は `~/.local/state/vim/`（リポジトリ外）に保存される。
  機密ファイル編集時の undo 履歴等がリポジトリに混入しないようにするため
- `~/.vim` はシンボリックリンクにしない（実ディレクトリ）。プラグイン本体と
  マシンローカル設定（`~/.vim/localrc/vimrc.vim`・gvimrc.vim。git 管理外）の置き場
- `claude/`・`codex/` は `~/.claude`・`~/.codex` へ**ファイル単位**でリンクする。
  ディレクトリ丸ごとリンクしないこと（セッション履歴・認証情報などの状態ファイルが同居しているため）
- Codex の `hooks.json` と `rules/default.rules` はリンクし、通常利用する権限プロファイル
  `personal-workspace` は `codex/permissions.toml` の内容を既存の `~/.codex/config.toml` へマージする。
  モデル・プラグイン・プロジェクト信頼設定など、Codex が管理する既存項目は保持される
- Codex の権限プロファイルは Codex 0.138.0 以降が必要。旧式の `sandbox_mode` または
  `[sandbox_workspace_write]` が `~/.codex/config.toml` に残っている場合、競合を避けるためセットアップは停止する
- 通常の `codex` 起動では `approval_policy = "on-request"` を使い、`git add` と `git commit` は
  明示的に承認を求める。承認後にGit操作を完了できるよう、ワークスペース内の `.git` は
  書き込み可能とするが、追加のセッション用権限プロファイルは作成しない
- 承認と sandbox の両方を意図的に外すセッションだけ `codex --yolo` で起動する。
  これは秘密情報へのdenyを含むローカル保護を迂回するため、信頼できる作業に限定する
- Codex はワークスペース外のファイルを既定で読み取れないようにし、実行に必要な
  `:minimal`、スタンドアロン・プラグイン配布のスキル、NVM 配下の実行環境のみ読み取りを許可する。
  ユーザー専用の `TMPDIR` はビルド・テスト用に書き込み可能とするが、共有の `/tmp` は拒否する。
  権限プロファイルはsandbox内のローカルコマンドに適用され、ユーザーまたは自動レビューが
  承認したsandbox外実行には適用されない
- `.git` の書き込み許可はGit以外のコマンドにも適用されるため、Codexの実行内容は承認画面で確認する
- 権限設定の更新前に `~/.codex/config.toml.dotfiles-backup` を作成する。
  更新前後の指紋比較で既存設定との競合を検知した場合は、上書きせず停止する。
  排他ロックにはプロセス ID を記録し、異常終了後の古いロックは次回実行時に回収する
- zsh の設定は `.zshenv`（全シェル共通の PATH）と `.zshrc`（対話シェル用）に分け、
  それぞれ末尾で `~/.zshenv.local`・`~/.zshrc.local` を読む。マシン固有のパスや
  自作ツールはこちらに置き、リポジトリ側にはハードコードした絶対パスを持ち込まない
- LM Studio・Docker Desktop・Antigravity などのインストーラは `~/.zshrc` に設定を
  追記してくる。リンク経由でリポジトリが書き換わるので、`git status` に出たら
  共通化するか `~/.zshrc.local` へ移すかを判断する
- `.zshrc` / `.zshenv` は macOS 専用のため `setup.bat` ではリンクしない
  （Windows のシェルは nyagos）
- `.gitconfig` は `~/.gitconfig.os` を include しており、OS 別の credential helper を
  `setup.sh`（→ `gitconfig.mac`）/ `setup.bat`（→ `gitconfig.win`）が切り替える
- `.gitignore` はこのリポジトリの ignore と git の `core.excludesfile`（グローバル ignore）を兼ねる
