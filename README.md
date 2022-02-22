Qubes RPC git SSH proxy
=======================

This is experimental, use with caution!

Motivation
----------

Many Git providers have a limited ACL model, so that often the most workable approach for a developer is to upload their SSH keys and inherit wide access to a range of repositories.
Qubes OS is inviting to spawn playgrounds for wild development journeys.
On other operating systems I have achieved that with compartmentalization and giving a trusted machine SSH access to the playground compartment, so that the trusted host can pull changes, verify them and forward to the upstream repository.
Unfortunately for the task, Qubes does not invite to configure networking between development compartments, but instead offers RPC.
This repository demonstrates a concept where a customized sys-firewall VM offers the `git.ProxySSH` RPC call that can be used as the clients SSH ProxyCommand.
By prompting a dialog on first access to a new repository, the user can confirm the ClientVM's access to a specific repository.

Goals
-----

- ClientVM is untrusted and cannot access Git SSH key (e.g. GitHub, GitLab, Gogs, etc).
- Trusted VM has a valid SSH key and offers `git.ProxySSH` RPC method.
- Feature can be enabled from ClientVM users .ssh/config without additional configuration.
- Does not require network.
- Opens a visual dialog when a ClientVM requests access to a Git repository.

