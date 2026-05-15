# Atlassian Forge
if command -v forge >/dev/null 2>&1; then
  . <(forge --completion)
fi

forge-use() {
  local profile="$1"
  local profile_file="$HOME/.forge-$profile"

  if [ -z "$profile" ]; then
    echo "Usage: forge-use <profile>"
    return 1
  fi

  if [ ! -f "$profile_file" ]; then
    echo "Missing $profile_file"
    return 1
  fi

  source "$profile_file"

  if command -v forge >/dev/null 2>&1; then
    forge whoami
  fi
}

if [ -z "$FORGE_EMAIL" ] && [ -z "$FORGE_API_TOKEN" ] && [ -f "$HOME/.forge-personal" ]; then
  source "$HOME/.forge-personal"
fi
