import subprocess
import pytest

SHELLS = [
    "bash",
    "zsh",
    "fish",
    "nu"
]

CLI_FILES = {
    "bash": "/klone-repo/bash/klone.sh",
    "zsh": "/klone-repo/zsh/klone.sh",
    "fish": "/klone-repo/functions/klone.fish",
    "nu": "/klone-repo/nushell/klone.nu"
}

# Format: (command, expected_output, expected_code, config_file)
TEST_CASES = [
    # Tests with default config (empty config file) - test all core functionality

    # Basic HTTPS URL parsing
    ("klone --dry-run https://github.com/user/repo", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),
    ("klone --dry-run https://github.com/user/repo.git", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),
    ("klone -n https://github.com/user/repo", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),

    # SSH URL parsing
    ("klone --dry-run git@github.com:user/repo.git", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),
    ("klone -n git@github.com:user/repo.git", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),
    ("klone --dry-run ssh://git@github.com/user/repo.git", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),
    ("klone -n ssh://git@github.com/user/repo.git", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),

    # Flag position
    ("klone https://github.com/foo/bar --dry-run", "would clone repo to /root/workspace/github/foo/bar", "", 0, "config-default.toml"),
    ("klone https://github.com/foo/bar -n", "would clone repo to /root/workspace/github/foo/bar", "", 0, "config-default.toml"),

    # Default domain (no alias)
    ("klone --dry-run https://gitlab.com/org/project", "would clone repo to /root/workspace/gitlab/org/project", "", 0, "config-default.toml"),
    ("klone --dry-run https://bitbucket.org/user/repo", "would clone repo to /root/workspace/bitbucket/user/repo", "", 0, "config-default.toml"),

    # Clone command verification (default)
    ("klone --dry-run https://github.com/user/repo", "would clone repo using git clone", "", 0, "config-default.toml"),

    # Complex paths
    ("klone --dry-run https://gitlab.com/org/team/sub/project", "would clone repo to /root/workspace/gitlab/org/team/sub/project", "", 0, "config-default.toml"),

    # Test base_dir configuration
    ("klone --dry-run https://github.com/user/repo", "would clone repo to /workspace/github/user/repo", "", 0, "config-base-dir.toml"),
    ("klone --dry-run git@gitlab.com:org/project.git", "would clone repo to /workspace/gitlab/org/project", "", 0, "config-base-dir.toml"),

    # Test domain_alias configuration
    ("klone --dry-run https://github.com/user/repo", "would clone repo to /root/workspace/gh/user/repo", "", 0, "config-domain-alias.toml"),
    ("klone --dry-run git@example.com:org/project.git", "would clone repo to /root/workspace/custom/path/org/project", "", 0, "config-domain-alias.toml"),

    # Test path_replace configuration
    ("klone --dry-run https://gitlab.com/old-team/project", "would clone repo to /root/workspace/gitlab/new-team/project", "", 0, "config-path-replace.toml"),
    ("klone --dry-run git@bitbucket.org:team-foo/repo.git", "would clone repo to /root/workspace/bitbucket/foo/repo", "", 0, "config-path-replace.toml"),

    # Test custom clone command
    ("klone --dry-run https://github.com/user/repo", "would clone repo using jj git clone --colocate", "", 0, "config-clone-command.toml"),
    ("klone --dry-run git@github.com:user/repo.git", "would clone repo using jj git clone --colocate", "", 0, "config-clone-command.toml"),

    # Test tilde expansion in base_dir
    ("klone --dry-run https://github.com/user/repo", "would clone repo to /root/code/github/user/repo", "", 0, "config-tilde.toml"),
    ("klone --dry-run git@github.com:user/repo.git", "would clone repo to /root/code/github/user/repo", "", 0, "config-tilde.toml"),

    # Test combined configuration (all features together)
    ("klone --dry-run https://github.com/user/repo", "would clone repo to /workspace/gh/user/repo", "", 0, "config-combined.toml"),
    ("klone --dry-run git@example.com:org/project.git", "would clone repo to /workspace/custom/path/org/project", "", 0, "config-combined.toml"),

    # Invalid URL schema (should fail)
    ("klone --dry-run ftp://github.com/user/repo", "", "Error: Invalid URL schema. Only git@, ssh://git@, and https:// URLs are supported.", 1, "config-default.toml"),
    ("klone --dry-run http://github.com/user/repo", "", "Error: Invalid URL schema. Only git@, ssh://git@, and https:// URLs are supported.", 1, "config-default.toml"),

    # Edge cases that might trigger bugs
    ("klone --dry-run https://github.com/user/repo/", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),  # Trailing slash
    ("klone --dry-run git@github.com:user/repo", "would clone repo to /root/workspace/github/user/repo", "", 0, "config-default.toml"),  # No .git suffix
    ("klone --dry-run https://github.com/user/repo-with-dashes", "would clone repo to /root/workspace/github/user/repo-with-dashes", "", 0, "config-default.toml"),  # Dashes in name
    ("klone --dry-run https://github.com/user/repo.name.with.dots", "would clone repo to /root/workspace/github/user/repo.name.with.dots", "", 0, "config-default.toml"),  # Dots in name
    ("klone --dry-run https://github.com/user/_repo", "would clone repo to /root/workspace/github/user/_repo", "", 0, "config-default.toml"),  # Leading underscore
    ("klone --dry-run https://github.com/user/123repo", "would clone repo to /root/workspace/github/user/123repo", "", 0, "config-default.toml"),  # Leading numbers
    ("klone --dry-run https://sub.github.com/user/repo", "would clone repo to /root/workspace/sub.github/user/repo", "", 0, "config-default.toml"),  # Subdomain
    ("klone --dry-run git@github.com:", "", "Error: Invalid URL schema. Only git@, ssh://git@, and https:// URLs are supported.", 1, "config-default.toml"),  # Incomplete SSH URL
    ("klone --dry-run https://", "", "Error: Invalid URL schema. Only git@, ssh://git@, and https:// URLs are supported.", 1, "config-default.toml"),  # Incomplete HTTPS URL
    ("klone --dry-run", "", "Error: Missing URL argument.", 1, "config-default.toml"),  # Missing URL
    ("klone --dry-run https://github.com", "", "", 1, "config-default.toml"),  # Missing path
]

def run_in_shell(shell, command, config_file):
    """Execute command in specific shell container"""
    container_name = f"klone-{shell}"
    cli_files = CLI_FILES[shell]
    config_path = f"/config/{config_file}"

    if shell in ["bash", "zsh"]:
        docker_cmd = [
            "docker", "exec", "-e", f"KLONE_CONFIG={config_path}",
            container_name,
            shell, "-c", f"source {cli_files} && {command}"
        ]
    elif shell == "fish":
        docker_cmd = [
            "docker", "exec", "-e", f"KLONE_CONFIG={config_path}",
            container_name,
            "fish", "-c", f"source {cli_files} && {command}"
        ]
    elif shell == "nu":
        docker_cmd = [
            "docker", "exec", "-e", f"KLONE_CONFIG={config_path}",
            container_name,
            "nu", "-c", f"source {cli_files}; {command}"
        ]
    else:
        raise ValueError(f"Unknown shell: {shell}")

    try:
        result = subprocess.run(docker_cmd, capture_output=True, text=True, timeout=30)
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"

@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("command,expected_output,expected_stderr,expected_code,config_file", TEST_CASES)
def test_klone(shell, command, expected_output, expected_stderr, expected_code, config_file):
    """Test klone command compatibility across different shells"""

    # Skip Nu for "klone --dry-run" test (missing URL) since Nu requires URL parameter
    if shell == "nu" and command == "klone --dry-run":
        return

    exit_code, stdout, stderr = run_in_shell(shell, command, config_file)

    if exit_code != expected_code or expected_output not in stdout or expected_stderr not in stderr:
        print(f"\n--- Debug Info for {shell} ---")
        print(f"Command: {command}")
        print(f"Expected exit code: {expected_code}, got: {exit_code}")
        print(f"Expected output: '{expected_output}'")
        print(f"Expected stderr: '{expected_stderr}'")
        print(f"Stdout: {repr(stdout)}")
        print(f"Stderr: {repr(stderr)}")
        print("--- End Debug ---")

    # Assertions
    assert exit_code == expected_code, f"Expected exit code {expected_code}, got {exit_code}"
    assert expected_output in stdout, f"Expected '{expected_output}' in stdout: {stdout}"
    assert expected_stderr in stderr, f"Expected '{expected_stderr}' in stderr: {stderr}"

def test_container_connectivity():
    """Verify all shell containers are accessible"""
    for shell in SHELLS:
        container = f"klone-{shell}"
        result = subprocess.run(
            ["docker", "exec", container, "echo", "test"],
            capture_output=True, text=True
        )
        assert result.returncode == 0, f"Container {container} not accessible"
        assert "test" in result.stdout
