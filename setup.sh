#!/bin/bash
for f in .??*
do
    [ "$f" = ".git" ] && continue
    [ "$f" = ".DS_Store" ] && continue
    [ "$f" = ".desktop" ] && continue
    [ "$f" = ".nyagos" ] && continue

    ln -s "$HOME"/dotfiles/"$f" "$HOME"/"$f"
done

#NeoVim
COPY_FROM="$HOME"/dotfiles
COPY_TO=~/.config/nvim
if [ ! -d $COPY_TO ]
then
    mkdir -p $COPY_TO
fi
ln -s "$COPY_FROM"/.vimrc "$COPY_TO"/init.vim
ln -s "$COPY_FROM"/.gvimrc "$COPY_TO"/ginit.vim
