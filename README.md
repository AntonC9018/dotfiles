The idea of this repository is to be able to quickly configure a new Ubuntu instance from scratch.
I'm only using this for WSL currently.


## Usage

First thing is cloning this repo:

```sh
git clone --recurse-submodules --shallow-submodules https://github.com/AntonC9018/dotfiles
```

Then you're supposed to call `./init/init_wsl.sh`.
This sets up a myriad of things:
- Installs various compilers;
- Installs depedencies used for initializing e.g. neovim;
- Installs tmux and neovim;
- Creates symlinks to the configuration files in `$HOME` to those in this repo;
- Sets up wsl-related services;
- Copies the github SSH key over from Windows.

Then, start the `zsh` shell to source the config and use that instead of `bash`:
```sh
zsh
```
