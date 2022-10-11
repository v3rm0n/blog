---
layout: post
title:  "Quickly switch between AWS profiles"
tags: aws infra shell
---

I have to deal with multiple AWS accounts of multiple customers every day, so I created this simple
alias snippet to make it easier to switch between accounts:

```zsh
alias profile="export AWS_PROFILE=\$(aws configure list-profiles | fzf --prompt \"Choose active AWS profile:\")"
```

It pops up a small prompt where you can choose the right profile with the arrow keys or search by
text. After you choose a profile it is exported to the environment, and you don't have to use the
*--region* flag every time you run a command.

*NB!* Needs [fzf][fzf].

# What profile is currently active?

Quick tip for **zsh** users: add the profile environment variable to **RPROMPT** (right side
of your shell prompt) for a quick glance to your
active profile: `RPROMPT='${AWS_PROFILE}'`

# Change profiles automatically

Another great trick is to change the profile automatically based on what directory you have open in
your shell. For that you can use [direnv][direnv] and add an *.envrc* file to every directory where
you need the profile to be changed, like:

```shell
export AWS_PROFILE=someprofile
```

It works recursively: you only need to add the file to the root directory.

[fzf]: https://github.com/junegunn/fzf
[direnv]: https://direnv.net
