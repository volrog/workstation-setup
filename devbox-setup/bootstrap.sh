#!/usr/bin/env bash
set -euo pipefail

SSH_PUBLIC_KEY="PASTE_YOUR_PUBLIC_KEY_HERE"
USERNAME="developer"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root."
  exit 1
fi

if [[ "${SSH_PUBLIC_KEY}" == "PASTE_YOUR_PUBLIC_KEY_HERE" || -z "${SSH_PUBLIC_KEY}" ]]; then
  echo "Edit bootstrap.sh and set SSH_PUBLIC_KEY before running it."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y sudo python3 python3-apt curl ca-certificates git

if ! id "${USERNAME}" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "${USERNAME}"
fi

usermod -aG sudo "${USERNAME}"

install -d -m 700 -o "${USERNAME}" -g "${USERNAME}" "/home/${USERNAME}/.ssh"
printf '%s\n' "${SSH_PUBLIC_KEY}" > "/home/${USERNAME}/.ssh/authorized_keys"
chmod 600 "/home/${USERNAME}/.ssh/authorized_keys"
chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.ssh/authorized_keys"

cat <<EOF

Bootstrap finished.

See README.md -> Manual Setup Checklist for all values and auth steps that must be handled manually.

Next steps from your local machine:

1. Exit the root SSH session:
   exit

2. Check SSH access as ${USERNAME}:
   ssh devbox

   Or, without ~/.ssh/config:
   ssh ${USERNAME}@SERVER_IP

3. Go to the local devbox setup directory:
   cd devbox-setup

4. Install Ansible locally if needed on macOS:
   brew install ansible

5. Copy and edit inventory:
   cp inventory.example.ini inventory.ini
   nano inventory.ini

6. Install Ansible collections:
   ansible-galaxy collection install -r requirements.yml

7. Check Ansible connection:
   ansible devbox -m ping

8. Run the playbook:
   ansible-playbook main.yml

EOF
