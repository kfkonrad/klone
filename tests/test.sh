#!/usr/bin/env bash

set -e

BASH_VERSION="5.3.3"
ZSH_VERSION="5.9"
FISH_VERSION="4.0.2"
NU_VERSION="0.106.1"

CONTAINERS=("klone-bash" "klone-zsh" "klone-fish" "klone-nu")

# Global variables for cleanup
VENV_DIR=""
CONFIG_DIR=""

cleanup() {
    echo "Cleaning up containers..."
    for container in "${CONTAINERS[@]}"; do
        docker rm -f "$container" 2>/dev/null || true
    done

    echo "Cleaning up virtual environment and config..."
    if [[ -n "$VENV_DIR" && -d "$VENV_DIR" ]]; then
        rm -rf "$VENV_DIR"
        echo "Removed venv: $VENV_DIR"
    fi
    if [[ -d "__pycache__" ]]; then
        rm -rf "__pycache__"
        echo "Removed pycache"
    fi

    if [[ -n "$CONFIG_DIR" && -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        echo "Removed config dir: $CONFIG_DIR"
    fi
}

trap cleanup EXIT

# Create Python virtual environment
echo "Creating Python virtual environment..."
VENV_DIR=$(mktemp -d -t klone-test-venv-XXXXXX)
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "Created and activated venv: $VENV_DIR"

# Create config directory with test TOML files
echo "Creating test config files..."
CONFIG_DIR=$(mktemp -d -t klone-test-config-XXXXXX)

# Default config - tests basic functionality
cat > "$CONFIG_DIR/config-default.toml" <<'EOF'
EOF

# Config with only base_dir set
cat > "$CONFIG_DIR/config-base-dir.toml" <<'EOF'
[general]
base_dir = "/workspace"
EOF

# Config with only domain_alias
cat > "$CONFIG_DIR/config-domain-alias.toml" <<'EOF'
[domain_alias]
github.com = "gh"
example.com = "custom/path"
EOF

# Config with only path_replace
cat > "$CONFIG_DIR/config-path-replace.toml" <<'EOF'
[path_replace]
gitlab.com = ["old", "new"]
bitbucket.org = ["team-", ""]
EOF

# Config with custom clone command
cat > "$CONFIG_DIR/config-clone-command.toml" <<'EOF'
[general]
clone_command = "jj git clone --colocate"
EOF

# Config with empty path replacement
cat > "$CONFIG_DIR/config-empty-replace.toml" <<'EOF'
[path_replace]
example.com = ["remove-this/", ""]
EOF

# Config with tilde expansion in base_dir
cat > "$CONFIG_DIR/config-tilde.toml" <<'EOF'
[general]
base_dir = "~/code"
EOF

# Config with everything combined
cat > "$CONFIG_DIR/config-combined.toml" <<'EOF'
[general]
base_dir = "/workspace"
cd_after_clone = true
clone_command = "jj git clone --colocate"

[domain_alias]
github.com = "gh"
example.com = "custom/path"

[path_replace]
gitlab.com = ["old", "new"]
EOF

echo "Created config dir at: $CONFIG_DIR"

# Bash Container
docker run -d --name "klone-bash" \
  -u 0:0 \
  -v "$(pwd)/..:/klone-repo" \
  -v "$CONFIG_DIR:/config" \
  -e HOME=/root \
  -w /workspace \
  ${DOCKER_USER_ARGS:-} \
  "bash:${BASH_VERSION}" sleep infinity

# ZSH Container
docker run -d --name "klone-zsh" \
  -u 0:0 \
  -v "$(pwd)/..:/klone-repo" \
  -v "$CONFIG_DIR:/config" \
  -e HOME=/root \
  -w /workspace \
  ${DOCKER_USER_ARGS:-} \
  "zshusers/zsh:${ZSH_VERSION}" sleep infinity

# Fish Container
docker run -d --name "klone-fish" \
  -u 0:0 \
  -v "$(pwd)/..:/klone-repo" \
  -v "$CONFIG_DIR:/config" \
  -e HOME=/root \
  -w /workspace \
  ${DOCKER_USER_ARGS:-} \
  "ohmyfish/fish:${FISH_VERSION}" sleep infinity

# Nushell Container
docker run -d --name "klone-nu" \
  -u 0:0 \
  -v "$(pwd)/..:/klone-repo" \
  -v "$CONFIG_DIR:/config" \
  -e HOME=/root \
  -w /workspace \
  --entrypoint /bin/sh \
  ${DOCKER_USER_ARGS:-} \
  "hustcer/nushell:${NU_VERSION}" -c 'sleep infinity'


echo "Installing pytest and running tests..."
pip install pytest
python -m pytest test_klone.py -v
