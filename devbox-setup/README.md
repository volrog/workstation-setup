# Devbox Setup

Minimal Ansible setup for a personal Ubuntu 24.04 LTS development server.

Target server:

- OS: Ubuntu 24.04 LTS
- User: `developer`
- Projects directory: `/home/developer/projects`
- Access: SSH keys only after Ansible hardening

This setup is intentionally simple: one bootstrap script, one inventory file, one playbook, small task files, and a few dotfiles.

## What Is Included

`bootstrap.sh` is the first-run script for a fresh VPS. It is meant to be run as `root` before Ansible can connect as `developer`.

It does only the minimum safe preparation:

- installs packages required for Ansible to work on the server
- creates the `developer` user
- adds `developer` to `sudo`
- creates `/home/developer/.ssh/authorized_keys`
- installs your public SSH key

System package upgrades are handled by Ansible, not by `bootstrap.sh`.

It does not disable root login or password authentication. The playbook does that later, after you verify that SSH access as `developer` works.

`inventory.example.ini` tells Ansible which server to configure. You copy it to `inventory.ini`, put your real server IP there, and keep `inventory.ini` local if it contains machine-specific details.

`ansible.cfg` makes Ansible use `inventory.ini` automatically when you run commands from this directory.

`default.config.yml` contains safe defaults such as feature flags, username, home directory, apt upgrade behavior, Node.js version, packages, directories, and firewall ports.

`config.example.yml` shows optional local overrides. Copy it to `config.yml` if you need changes. `config.yml` is gitignored.

`requirements.yml` lists Ansible collections used by the playbook.

`main.yml` is the main Ansible playbook. It imports small task files from `tasks/` for packages, directories, firewall, SSH hardening, fail2ban, unattended security upgrades, Docker, Node.js, Bun, OpenCode, dotfiles, and Caddy.

## Layout

```text
devbox-setup/
  README.md
  ansible.cfg
  bootstrap.sh
  inventory.example.ini
  default.config.yml
  config.example.yml
  requirements.yml
  main.yml
  tasks/
    packages.yml
    directories.yml
    firewall.yml
    ssh.yml
    fail2ban.yml
    unattended-upgrades.yml
    docker.yml
    node.yml
    bun.yml
    opencode.yml
    dotfiles.yml
    caddy.yml
  dotfiles/
    gitconfig
    tmux.conf
    zshrc
  scripts/
    git-namespace-config
  examples/
    Caddyfile.example
```

## Manual Setup Checklist

Before running the full setup, provide machine-specific values and complete external auth steps.

Files to edit locally:

- `~/.ssh/config`: replace `SERVER_IP` with your VPS IP.
- `bootstrap.sh`: replace `PASTE_YOUR_PUBLIC_KEY_HERE` with your public SSH key.
- `inventory.ini`: copy from `inventory.example.ini` and replace `SERVER_IP`, unless you use `Host devbox` in `~/.ssh/config`.
- `config.yml`: optional local overrides copied from `config.example.yml`.

Values to review:

- `devbox_user`: defaults to `developer`.
- `devbox_home`: defaults to `/home/developer`.
- `devbox_apt_upgrade`: defaults to `true`.
- `devbox_docker_add_user_to_group`: defaults to `true` for devbox convenience, but gives root-equivalent Docker access.
- `devbox_docker_protect_ufw`: defaults to `true` to block accidental public Docker port exposure through `DOCKER-USER`.
- `devbox_node_version`: defaults to `22`.
- `devbox_firewall_ports`: defaults to `22`, `80`, and `443` because this devbox commonly exposes web projects through Caddy.
- feature flags such as `configure_caddy`, `configure_docker`, and `configure_opencode`.
- security feature flags such as `configure_ssh`, `configure_fail2ban`, and `configure_unattended_upgrades`.

Manual steps after provisioning:

- reconnect over SSH after Docker group membership changes.
- run `gh auth login`.
- run `forge login`.
- run `opencode` and connect an LLM provider.
- create namespace Git configs with `git-namespace-config <namespace>` when needed.
- configure `/etc/caddy/Caddyfile` manually if you want public domains.
- create DNS `A` records for Caddy-managed domains.

## Create SSH Key

Create a dedicated SSH key for the devbox on your local machine:

```sh
ssh-keygen -t ed25519 -C "devbox" -f ~/.ssh/devbox_ed25519
```

Your public key will be in:

```sh
~/.ssh/devbox_ed25519.pub
```

Your private key is:

```sh
~/.ssh/devbox_ed25519
```

Never commit the private key.

## Configure SSH

Add this to your local `~/.ssh/config`:

```sshconfig
Host devbox
  HostName SERVER_IP
  User developer
  IdentityFile ~/.ssh/devbox_ed25519
  IdentitiesOnly yes
  ServerAliveInterval 30
  ServerAliveCountMax 3
```

Replace `SERVER_IP` with your VPS IP.

After this, you can connect with:

```sh
ssh devbox
```

Ansible can also use the same `Host devbox` entry, so your inventory can be just `devbox` if you prefer.

## Run Bootstrap On A New VPS

On your local machine, open `bootstrap.sh` and replace:

```sh
SSH_PUBLIC_KEY="PASTE_YOUR_PUBLIC_KEY_HERE"
```

with the content of `~/.ssh/devbox_ed25519.pub`.

Copy the script to the server as `root`:

```sh
scp bootstrap.sh root@SERVER_IP:/root/bootstrap.sh
```

Run it on the server:

```sh
ssh root@SERVER_IP
bash /root/bootstrap.sh
```

Then check that the new user works:

```sh
ssh devbox
```

Do not continue until SSH access as `developer` works.

## Install Ansible On macOS

Install Ansible locally on your Mac:

```sh
brew install ansible
```

Check it:

```sh
ansible --version
```

Install required Ansible collections from the `devbox-setup` directory:

```sh
ansible-galaxy collection install -r requirements.yml
```

## Prepare Inventory

Copy the example inventory:

```sh
cp inventory.example.ini inventory.ini
```

Edit `inventory.ini`:

```ini
[devboxes]
devbox ansible_host=SERVER_IP ansible_user=developer
```

If your `~/.ssh/config` already has `Host devbox`, this can be enough:

```ini
[devboxes]
devbox
```

## Check Ansible Connection

From the `devbox-setup` directory:

```sh
ansible devbox -m ping
```

Expected result includes:

```text
SUCCESS
```

## Overriding Defaults

The default configuration lives in `default.config.yml`. Do not edit it for machine-specific settings unless you want to change the repository defaults.

For local overrides, copy the example config:

```sh
cp config.example.yml config.yml
```

Then edit `config.yml`:

```sh
nano config.yml
```

For example, disable Caddy on a server where you do not need reverse proxy support:

```yaml
configure_caddy: false
```

Or change the default Node.js version installed by NVM:

```yaml
devbox_node_version: "22"
```

Feature flags decide what is part of a full run. Tags decide what to run this time.

## Run The Playbook

From the `devbox-setup` directory:

```sh
ansible-playbook main.yml
```

The playbook will:

- update the apt cache and upgrade installed apt packages when `devbox_apt_upgrade` is enabled
- install development tools
- create `/home/developer/projects`, `/home/developer/sandbox`, and `/home/developer/scripts`
- enable UFW and allow only SSH, HTTP, and HTTPS
- enforce SSH public key authentication only
- disable SSH password, keyboard-interactive, and root login
- limit SSH login to the configured `devbox_user`
- validate SSH config before reloading SSH
- install and enable fail2ban for `sshd`
- install `unattended-upgrades` and enable daily security update checks
- install Docker and Docker Compose v2 from Ubuntu packages
- add `developer` to the `docker` group when `devbox_docker_add_user_to_group` is enabled
- install `DOCKER-USER` firewall protection when `devbox_docker_protect_ufw` is enabled
- install NVM for `developer`
- install Node.js `22` through NVM; npm is included with Node.js
- install configured global npm packages, including Atlassian Forge CLI
- install Bun through the official installer
- install OpenCode through the official installer
- copy `.gitconfig`, `.tmux.conf`, and `.zshrc`
- install `~/scripts/git-namespace-config` for per-namespace Git config
- set `/usr/bin/zsh` as the default shell
- install Caddy without overwriting `/etc/caddy/Caddyfile`

You can also run only one part using tags:

```sh
ansible-playbook main.yml --tags docker
ansible-playbook main.yml --tags ssh
ansible-playbook main.yml --tags fail2ban
ansible-playbook main.yml --tags unattended-upgrades
ansible-playbook main.yml --tags node
ansible-playbook main.yml --tags bun
ansible-playbook main.yml --tags opencode
ansible-playbook main.yml --tags dotfiles
```

After Docker group membership changes, reconnect to SSH. This is only needed when `devbox_docker_add_user_to_group` is enabled:

```sh
exit
ssh devbox
```

## Check Tools

Check Docker:

```sh
docker --version
docker compose version
docker run hello-world
```

Check Node.js and npm:

```sh
node --version
npm --version
nvm --version
bun --version
```

Check GitHub CLI, Atlassian Forge CLI, and OpenCode:

```sh
gh --version
forge --version
opencode --version
```

Authenticate manually after provisioning:

```sh
gh auth login
forge login
opencode
```

If a project has an `.nvmrc`, switch to its Node.js version from the project directory:

```sh
nvm use
```

## Project Git Configs

The base Git config is copied to `~/.gitconfig`. It uses your default name, email, `vim` as the Git editor, `autocrlf = input`, `master` as the default branch, and rebase-on-pull.

For company-specific or namespace-specific settings, use the helper installed by the playbook:

```sh
git-namespace-config actonic
```

This creates:

```text
~/projects/actonic/.gitconfig
```

It also adds this include to `~/.gitconfig` if it is not already there:

```ini
[includeIf "gitdir:~/projects/actonic/"]
  path = ~/projects/actonic/.gitconfig
```

Then put namespace-specific settings in `~/projects/actonic/.gitconfig`:

```ini
[user]
  email = your.work@email.com
```

Any repository inside `~/projects/actonic/` will use that namespace config. You can run the helper again later for new namespaces; it is safe to repeat for the same namespace.

## tmux Basics

Create a session:

```sh
tmux new -s work
```

Detach from a session:

```text
Ctrl-b d
```

Attach again:

```sh
tmux attach -t work
```

Reload config from inside tmux:

```text
Ctrl-b r
```

The included config enables true color, mouse support, larger scrollback, vi copy mode, 1-based window/pane indexes, automatic window renumbering, focus events, and clipboard integration.

## Remote IDE Access

Use the same SSH config entry for remote development tools.

Zed Remote SSH:

- connect to `devbox`
- open `/home/developer/projects`

WebStorm Gateway:

- create a new SSH connection using host `devbox`
- use `/home/developer/projects` as the project root area

VS Code Remote SSH:

- install the Remote SSH extension
- run `Remote-SSH: Connect to Host...`
- choose `devbox`
- open `/home/developer/projects`

## Caddy And Domains

Caddy is enabled by default and UFW opens `80/tcp` and `443/tcp` by default. This matches the common devbox workflow where projects need a public HTTPS endpoint or tunnel-like reverse proxy.

This also means anything you add to `/etc/caddy/Caddyfile` is intentionally public. Keep application servers bound to `127.0.0.1`, then expose only selected domains through Caddy.

`examples/Caddyfile.example` contains example reverse proxies:

- `dev.example.com` to `127.0.0.1:3000`
- `api.dev.example.com` to `127.0.0.1:4000`
- `vite.dev.example.com` to `127.0.0.1:5173`

To use it, create DNS `A` records pointing your domains to the VPS IP. If DNS is correct and ports `80` and `443` are open, Caddy will automatically get HTTPS certificates.

The playbook installs Caddy but does not overwrite `/etc/caddy/Caddyfile`. Copy and edit the example manually when you are ready:

```sh
sudo cp examples/Caddyfile.example /etc/caddy/Caddyfile
sudo nano /etc/caddy/Caddyfile
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
```

Use a domain instead of ngrok only when the service runs on the VPS. For example, if your Vite app runs on the VPS at `127.0.0.1:5173`, Caddy can expose it as `https://vite.dev.example.com`.

If the service runs locally on your MacBook, a domain pointing to the VPS does not automatically replace ngrok. You still need a reverse tunnel, ngrok, frp, Tailscale Funnel, Cloudflare Tunnel, or a similar tunnel solution.

For sensitive development sites, add authentication in Caddy. Generate a password hash on the server:

```sh
caddy hash-password
```

Then use `basic_auth` in the site block:

```caddyfile
admin.dev.example.com {
  basic_auth {
    devuser HASH_FROM_CADDY_HASH_PASSWORD
  }

  reverse_proxy 127.0.0.1:8080
}
```

Check the public web surface after changes:

```sh
sudo ufw status verbose
sudo ss -tulpn
sudo caddy validate --config /etc/caddy/Caddyfile
```

If a server does not need public web access, disable Caddy and leave only SSH open in `config.yml`:

```yaml
configure_caddy: false
devbox_firewall_ports:
  - "22"
```

## Docker Security

Membership in the `docker` group is root-equivalent on the server. If an attacker gets access to `developer` and that user can run Docker, they can usually escalate to full host control by mounting host paths into a container.

For convenience, `devbox_docker_add_user_to_group` defaults to `true`. Set it to `false` in `config.yml` if you prefer to run Docker through `sudo` instead:

```yaml
devbox_docker_add_user_to_group: false
```

Docker can publish ports in a way that bypasses UFW's normal incoming policy. This setup installs a small `DOCKER-USER` chain guard when `devbox_docker_protect_ufw` is enabled. It blocks new external traffic forwarded into Docker bridge networks while preserving container outbound traffic and established connections.

Keep development services bound to localhost, then expose only intentional public traffic through Caddy:

```sh
docker run -p 127.0.0.1:3000:3000 your-app
```

Avoid publishing dev services directly to all interfaces:

```sh
docker run -p 3000:3000 your-app
```

## Security Notes

- Do not commit private SSH keys.
- Do not commit `.env` files.
- Do not commit tokens or credentials.
- Do not commit GitHub CLI, Forge CLI, or OpenCode auth files.
- Use a separate Git SSH key on the devbox.
- Treat the `docker` group as root-equivalent access.
- Do not expose development ports like `3000`, `4000`, or `5173` directly to the internet.
- Expose public web traffic through Caddy on `80` and `443`.
- Use Caddy basic auth for sensitive development sites.
- Keep `inventory.ini` local if it contains private hostnames or IP addresses.
- Keep `config.yml` local if it contains machine-specific overrides.

## Dotfiles Note

The dotfiles here are intentionally local and minimal. If the same shell, Git, and tmux config should later be shared between the devbox and macOS setup, move them to a separate dotfiles repository and clone or sync them from both setups.
