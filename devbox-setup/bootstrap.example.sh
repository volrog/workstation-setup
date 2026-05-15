#!/usr/bin/env bash
set -euo pipefail

SSH_PUBLIC_KEY="PASTE_YOUR_PUBLIC_KEY_HERE"
SUDO_PASSWORD="PASTE_DEVELOPER_SUDO_PASSWORD_HERE"
USERNAME="developer"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root."
  exit 1
fi

if [[ "${SSH_PUBLIC_KEY}" == "PASTE_YOUR_PUBLIC_KEY_HERE" || -z "${SSH_PUBLIC_KEY}" ]]; then
  echo "Edit bootstrap.sh and set SSH_PUBLIC_KEY before running it."
  exit 1
fi

if [[ "${SUDO_PASSWORD}" == "PASTE_DEVELOPER_SUDO_PASSWORD_HERE" || -z "${SUDO_PASSWORD}" ]]; then
  echo "Edit bootstrap.sh and set SUDO_PASSWORD before running it."
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y sudo python3 python3-apt curl ca-certificates git

if ! id "${USERNAME}" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "${USERNAME}"
fi

printf '%s:%s\n' "${USERNAME}" "${SUDO_PASSWORD}" | chpasswd
usermod -aG sudo "${USERNAME}"

install -d -m 700 -o "${USERNAME}" -g "${USERNAME}" "/home/${USERNAME}/.ssh"
printf '%s\n' "${SSH_PUBLIC_KEY}" > "/home/${USERNAME}/.ssh/authorized_keys"
chmod 600 "/home/${USERNAME}/.ssh/authorized_keys"
chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.ssh/authorized_keys"

cat <<EOF

Bootstrap finished.

Save the sudo password for ${USERNAME} in your password manager.
Ansible will ask for it when you run the playbook with --ask-become-pass.

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

8. Run the playbook and enter the sudo password when prompted:
   ansible-playbook main.yml --ask-become-pass

EOF
