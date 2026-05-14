The idea of this repository is to be able to quickly configure a new Ubuntu instance from scratch.
I'm only using this for WSL currently.

## Known issues

Mason fails to install pyright, ts_ls, html and tailwindcss.

## Usage

First thing is cloning this repo:

```sh
git clone https://github.com/AntonC9018/dotfiles
```

Then you're supposed to call `bash ./init/init_wsl.sh`.
This sets up a myriad of things:
- Installs various compilers;
- Installs depedencies used for initializing e.g. neovim;
- Installs tmux and neovim;
- Creates symlinks to the configuration files in `$HOME` to those in this repo;
- Sets up wsl-related services;
- Copies the github SSH key over from Windows;
- Changes shell to `zsh`;
- Initializes submodules;
- Starts `zsh`.

## Instructions together with WSL

```bash
wsl --install -d Ubuntu --name ubuntu1 --location D:\wsl\ubuntu1
cd ~
git clone https://github.com/AntonC9018/dotfiles
cd dotfiles
bash ./init/init_wsl.sh
nvim .
```
