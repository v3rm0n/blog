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

Another quick tip for **zsh** users: add the profile environment variable to **RPROMPT** (right side
of your shell prompt) for a quick glance to your
active profile: `RPROMPT='${AWS_PROFILE}'`

[fzf]: https://github.com/junegunn/fzf