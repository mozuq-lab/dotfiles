#!/bin/bash
for f in .??*
do
    [ "$f" = ".git" ] && continue

    ln -s "$HOME"/dotfiles/"$f" "$HOME"/"$f"
done
