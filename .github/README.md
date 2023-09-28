# My dotfiles

## Usage:

```bash
# Install: curl git bash zsh
# chsh -s /bin/zsh
cd ~
git clone --depth=1 https://github.com/Bash-it/bash-it.git ~/.bash_it
sh -c "$(curl -fsLS git.io/chezmoi)" -- init --apply richard-hajek
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
