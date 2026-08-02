#!/bin/bash
set -eu
cd "$(dirname "$0")"
DOTFILES=$(pwd)

# ~/.vim はリポジトリ外の実ディレクトリ（プラグイン・ローカル設定置き場）
# 旧構成のシンボリックリンクが残っていれば実ディレクトリに置き換える
if [ -L "$HOME"/.vim ]; then
    rm "$HOME"/.vim
fi
mkdir -p "$HOME"/.vim

for f in .??*
do
    case "$f" in
        .git|.DS_Store|.desktop|.nyagos|.vim) continue ;;
    esac
    # 既存の実ファイル（ツールのインストーラが書いた ~/.zshrc など）は
    # リンクで潰さずに退避する。2回目以降はリンクなのでこの分岐に入らない
    if [ -f "$HOME"/"$f" ] && [ ! -L "$HOME"/"$f" ]; then
        mv "$HOME"/"$f" "$HOME"/"$f".dotfiles-backup
        echo "既存の $HOME/$f を $HOME/$f.dotfiles-backup へ退避した"
    fi
    ln -snf "$DOTFILES"/"$f" "$HOME"/"$f"
done

# OS別 gitconfig（.gitconfig の include から参照される）
ln -snf "$DOTFILES"/gitconfig.mac "$HOME"/.gitconfig.os

# NeoVim
NVIM_DIR="$HOME"/.config/nvim
mkdir -p "$NVIM_DIR"
ln -snf "$DOTFILES"/.vimrc "$NVIM_DIR"/init.vim
ln -snf "$DOTFILES"/.gvimrc "$NVIM_DIR"/ginit.vim

# Claude Code（状態ファイルが同居するためディレクトリ丸ごとではなくファイル単位でリンク）
mkdir -p "$HOME"/.claude/local-plugins
ln -snf "$DOTFILES"/claude/settings.json "$HOME"/.claude/settings.json
ln -snf "$DOTFILES"/claude/statusline-command.sh "$HOME"/.claude/statusline-command.sh
ln -snf "$DOTFILES"/claude/local-plugins/dart-lsp "$HOME"/.claude/local-plugins/dart-lsp

# Codex
mkdir -p "$HOME"/.codex/rules
ln -snf "$DOTFILES"/codex/hooks.json "$HOME"/.codex/hooks.json
ln -snf "$DOTFILES"/codex/rules/default.rules "$HOME"/.codex/rules/default.rules
bash "$DOTFILES"/codex/install-permissions.sh \
    "$HOME"/.codex/config.toml \
    "$DOTFILES"/codex/permissions.toml
