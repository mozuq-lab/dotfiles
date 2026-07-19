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
- `.gitconfig` は `~/.gitconfig.os` を include しており、OS 別の credential helper を
  `setup.sh`（→ `gitconfig.mac`）/ `setup.bat`（→ `gitconfig.win`）が切り替える
- `.gitignore` はこのリポジトリの ignore と git の `core.excludesfile`（グローバル ignore）を兼ねる
