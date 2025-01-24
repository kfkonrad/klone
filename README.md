# klone

[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

Clone repos into the right directory in your workspace

The "right" directory is a path computed by klone. It takes the URL you're cloning from an turns it into a deterministic
path. E.g. `https://github.com/kfkonrad/klone` would get cloned to `~/workspace/github/kfkonrad/klone`. The exact
behavior is configurable, see [Usage](#usage) for more.

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Install

There are three implementations of `klone` with an identical feature set for Fish, Bash and ZSH.

### Fish

This repo is an oh my fish and fisher compatible plugin repo.

To install `klone` with oh my fish run:

```sh
omf install https://github.com/kfkonrad/klone.git
```

To install `klone` with fisher run:

```sh
fisher install kfkonrad/klone
```

### Bash

To install `klone` you can download
[bash/klone.sh](https://github.com/kfkonrad/klone/blob/main/bash/klone.sh) and source it in your `.bashrc`. Below are
examples for installing the script using `curl` and `wget` for added convenience:

Install with `curl`:

```sh
mkdir -p ~/.config/klone
curl https://raw.githubusercontent.com/kfkonrad/klone/main/bash/klone.sh -so ~/.config/klone/klone.sh
echo 'source ~/.config/klone/klone.sh' >> ~/.bashrc
```

Install with `wget`:

```sh
mkdir -p ~/.config/klone
wget https://raw.githubusercontent.com/kfkonrad/klone/main/bash/klone.sh -qO ~/.config/klone/klone.sh
echo 'source ~/.config/klone/klone.sh' >> ~/.bashrc
```

### ZSH

To install `klone` you can download
[zsh/klone.sh](https://github.com/kfkonrad/klone/blob/main/zsh/klone.sh) and source it in your `.zshrc`. Below are
examples for installing the script using `curl` and `wget` for added convenience:

Install with `curl`:

```sh
mkdir -p ~/.config/klone
curl https://raw.githubusercontent.com/kfkonrad/klone/main/zsh/klone.sh -so ~/.config/klone/klone.sh
echo 'source ~/.config/klone/klone.sh' >> ~/.zshrc
```

Install with `wget`:

```sh
mkdir -p ~/.config/klone
wget https://raw.githubusercontent.com/kfkonrad/klone/main/zsh/klone.sh -qO ~/.config/klone/klone.sh
echo 'source ~/.config/klone/klone.sh' >> ~/.zshrc
```

## Usage

To clone a repo simply run `klone <URL>`. `klone` supports SSH, git and HTTPS URLs with the same format `git` uses.

`klone` is configured with a TOML file. By default it's expected to be in `~/.config/klone/config.toml`, though you can
override this by setting `KLONE_CONFIG`.

The TOML config has three sections: `[general]`, `[domain_alias]` and `[path_replace]`.

### `[general]`

This section has three keys and changes the behavior of `klone` for all URLs:

| key              | description                                                    | default       |
|------------------|----------------------------------------------------------------|---------------|
| `base_dir`       | Set the base workspace directory all repos will be cloned into | `~/workspace` |
| `cd_after_clone` | `cd` into the newly cloned repo                                | `false`       |
| `clone command`  | Set the command used for cloning repos                         | `git clone`   |

### `[domain_alias]`

In `[domain_alias]` you can alias domains to arbitrary strings. This allows you to change the part of the repo's path
that's calculated from the URL. By default this is the first part of the FQDN up until the first dot, e.g. `github.com`
-> `github` or `foo.example.com` -> foo.

The format for this is `<domain> = "my-alias"`.

### `[path_replace]`

With `[path_replace]` you can replace parts of the URL path (which by default is taken as is, only a trailing `.git`
gets removed if present). This also supports regexes.

Note that with the Bash and ZSH implementations any slashes need to be escaped once, since they use `sed` internally.
The fish version has no such restriction.

The format for this is `<domain> = ["replace_me", "with_this"]`.

Do not format the array into multiple lines, the TOML parsers implemented in Bash/ZSH/Fish for this project do not have
multi-line support.

### Example `config.toml`

```toml
[domain_alias]
github.com = "foo/bar"
[path_replace]
gitlab.com = ["rluna", "baz"]
[general]
base_dir = "~/code"
cd_after_clone = true
clone_command = "jj git clone --colocate"
```

With this config running `klone https://github.com/kfkonrad/klone.git` would be cloned into
`~/code/foo/bar/kfkonrad/klone` using `jj git clone --colocate https://github.com/kfkonrad/klone.git`. After the clone
is finished, the user's shell would `cd` into `~/code/foo/bar/kfkonrad/klone`.

Running `klone https://gitlab.com/rluna-database/nosql/mongodb/mongo` with the config above would clone the repo into
`~/code/gitlab/baz-database/nosql/mongodb/mongo` using
`jj git clone --colocate https://gitlab.com/rluna-database/nosql/mongodb/mongo`. Afterwards `klone` would `cd` into
`~/code/gitlab/baz-database/nosql/mongodb/mongo`.

The `clone_command` is always run from the parent of the target directory (`~/code/foo/bar/kfkonrad/` in this case),
since that has the broadest compatibility with other version control systems such as Subversion, Jujutsu, Mercurial etc.
This also means the `clone_command` is run as is and only the URL is supplied as an additional argument.

## Maintainers

[@kfkonrad](https://github.com/kfkonrad)

## Contributing

PRs accepted.

Small note: If editing the README, please conform to the
[standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

MIT © 2025 Kevin F. Konrad
