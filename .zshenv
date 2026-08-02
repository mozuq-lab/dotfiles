# 非対話シェルを含む全シェルで読まれる。PATH の定義だけを置き、
# エイリアス・プロンプトなど対話シェル向けの設定は .zshrc に書く。
# このマシンだけで使うものは ~/.zshenv.local へ（git 管理外）。

# uv・Antigravity CLI などが実行ファイルを置く user-local bin
export PATH="$HOME/.local/bin:$PATH"

# マシン固有の設定
[ -f "$HOME/.zshenv.local" ] && . "$HOME/.zshenv.local"
