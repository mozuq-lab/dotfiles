# 対話シェル用の設定。全シェル共通の PATH は .zshenv に書く。
# このマシンだけで使うものは ~/.zshrc.local へ（git 管理外）。
#
# 各ツールのインストーラ（LM Studio・Docker Desktop・Antigravity など）は
# このファイルに設定を追記してくることがある。シンボリックリンク経由で
# リポジトリが書き換わるので、git status に出たら共通化するか
# ~/.zshrc.local へ移すか判断する。

# ---- PATH ----------------------------------------------------------------
# LM Studio CLI（lms）
[ -d "$HOME/.lmstudio/bin" ] && export PATH="$PATH:$HOME/.lmstudio/bin"

# fvm（Flutter のバージョン管理）
[ -d "$HOME/fvm/default/bin" ] && export PATH="$PATH:$HOME/fvm/default/bin"

# ---- nvm -----------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---- 補完 ----------------------------------------------------------------
# Docker CLI の補完定義（Docker Desktop を入れているマシンのみ）
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit

# ---- 環境変数 ------------------------------------------------------------
export SAM_CLI_TELEMETRY=0

# ---- エイリアス ----------------------------------------------------------
alias claude-dsp='claude --dangerously-skip-permissions'

# ---- プロンプト・シェルの挙動 --------------------------------------------
# 末尾にスラッシュが付いたパスで起動したときにカレントディレクトリを正規化する
[[ $PWD != / && $PWD == */ ]] && cd "${PWD%/}"

PROMPT='%F{cyan}%n@%m%f %F{yellow}%1~%f %# '

# ---- マシン固有の設定 ----------------------------------------------------
[ -f "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"
