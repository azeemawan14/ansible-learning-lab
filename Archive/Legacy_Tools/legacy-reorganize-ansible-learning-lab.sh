#!/usr/bin/env bash

set -Eeuo pipefail

usage() {
    echo "Usage: $0 /path/to/ansible-learning-lab"
    echo "Example: $0 ~/ansible-learning-lab"
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    usage
    exit 0
fi

if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

repo_input=$1

if [[ ! -d $repo_input ]]; then
    echo "ERROR: Directory does not exist: $repo_input" >&2
    exit 1
fi

repo=$(cd -- "$repo_input" && pwd -P)

# Safety check: refuse to operate on a directory that does not resemble this lab.
if [[ ! -f "$repo/README.md" || ! -d "$repo/study-notes" ]]; then
    echo "ERROR: This does not appear to be the ansible-learning-lab repository." >&2
    echo "Expected README.md and study-notes/ inside: $repo" >&2
    exit 1
fi

echo "Repository: $repo"
echo
echo "This script will:"
echo "  1. Create a timestamped backup (excluding .git)."
echo "  2. Create the recommended directory structure."
echo "  3. Move known files only when the destination does not already exist."
echo "  4. Leave the .git directory and Git history unchanged."
echo
read -r -p "Continue? Type YES: " confirmation

if [[ $confirmation != "YES" ]]; then
    echo "Cancelled. No changes were made."
    exit 0
fi

timestamp=$(date '+%Y%m%d-%H%M%S')
repo_parent=$(dirname -- "$repo")
repo_name=$(basename -- "$repo")
backup_file="$repo_parent/${repo_name}-before-reorganization-${timestamp}.tar.gz"

echo "Creating backup: $backup_file"
tar \
    --exclude="$repo_name/.git" \
    --exclude="$repo_name/.git/*" \
    -czf "$backup_file" \
    -C "$repo_parent" \
    "$repo_name"

directories=(
    "inventories/lab/group_vars"
    "inventories/lab/host_vars"
    "playbooks"
    "roles/common/tasks"
    "roles/common/handlers"
    "roles/common/templates"
    "roles/common/files"
    "roles/common/defaults"
    "roles/common/vars"
    "roles/webserver"
    "roles/appserver"
    "roles/database"
    "study-notes/english/01-introduction"
    "study-notes/english/02-control-node-setup"
    "study-notes/english/03-ssh"
    "study-notes/english/04-configuration"
    "study-notes/english/05-inventory"
    "study-notes/english/06-ad-hoc-commands"
    "study-notes/english/07-modules"
    "study-notes/english/08-playbooks"
    "study-notes/english/09-variables"
    "study-notes/english/10-conditionals-loops"
    "study-notes/english/11-handlers-templates"
    "study-notes/english/12-roles"
    "study-notes/english/13-troubleshooting"
    "study-notes/roman-urdu/01-introduction"
    "study-notes/roman-urdu/02-control-node-setup"
    "study-notes/roman-urdu/03-ssh"
    "study-notes/roman-urdu/04-configuration"
    "study-notes/roman-urdu/05-inventory"
    "study-notes/roman-urdu/06-ad-hoc-commands"
    "study-notes/roman-urdu/07-modules"
    "study-notes/roman-urdu/08-playbooks"
    "study-notes/roman-urdu/09-variables"
    "study-notes/roman-urdu/10-conditionals-loops"
    "study-notes/roman-urdu/11-handlers-templates"
    "study-notes/roman-urdu/12-roles"
    "study-notes/roman-urdu/13-troubleshooting"
    "exercises/guided-labs"
    "exercises/practice-tasks"
    "exercises/solutions"
    "projects/01-deploy-nginx"
    "projects/02-user-management"
    "projects/03-system-patching"
    "projects/04-three-tier-application"
    "troubleshooting/ssh"
    "troubleshooting/inventory"
    "troubleshooting/privilege-escalation"
    "troubleshooting/playbook-errors"
    "scripts"
    "resources/diagrams"
    "resources/screenshots"
    "resources/references"
)

echo "Creating directories..."
for directory in "${directories[@]}"; do
    mkdir -p -- "$repo/$directory"
done

safe_move() {
    local source_path=$1
    local destination_path=$2

    if [[ ! -e $source_path ]]; then
        return 0
    fi

    if [[ -e $destination_path ]]; then
        echo "SKIP: Destination already exists: $destination_path"
        return 0
    fi

    mkdir -p -- "$(dirname -- "$destination_path")"
    mv -- "$source_path" "$destination_path"
    echo "MOVED: ${source_path#"$repo/"} -> ${destination_path#"$repo/"}"
}

move_directory_contents() {
    local source_directory=$1
    local destination_directory=$2
    local item destination

    [[ -d $source_directory ]] || return 0
    mkdir -p -- "$destination_directory"

    shopt -s nullglob dotglob
    for item in "$source_directory"/*; do
        [[ $(basename -- "$item") == ".gitkeep" ]] && continue
        destination="$destination_directory/$(basename -- "$item")"

        if [[ -e $destination ]]; then
            echo "SKIP: Destination already exists: $destination"
        else
            mv -- "$item" "$destination"
            echo "MOVED: ${item#"$repo/"} -> ${destination#"$repo/"}"
        fi
    done
    shopt -u nullglob dotglob
}

echo "Reorganizing known files..."

# Move the main Ansible configuration and inventory to conventional locations.
safe_move "$repo/automation/ansible.cfg" "$repo/ansible.cfg"
safe_move "$repo/automation/inventory" "$repo/inventories/lab/hosts.ini"
move_directory_contents "$repo/automation/playbooks" "$repo/playbooks"

# Move English notes into topic directories.
safe_move "$repo/study-notes/english/Ansible_Control_Node_Setup_Rocky_Linux_9.md" \
          "$repo/study-notes/english/02-control-node-setup/ansible-control-node-setup-rocky-linux-9.md"
safe_move "$repo/study-notes/english/SSH_Custom_Key_Filename_Ansible_Study_Notes.md" \
          "$repo/study-notes/english/03-ssh/ssh-custom-key-filename.md"
safe_move "$repo/study-notes/english/configuration/Ansible_Config_Study_Notes.md" \
          "$repo/study-notes/english/04-configuration/ansible-config.md"
safe_move "$repo/study-notes/english/inventory/Ansible_Static_Inventory_Personal_Lab_Study_Notes.md" \
          "$repo/study-notes/english/05-inventory/ansible-static-inventory.md"
safe_move "$repo/study-notes/english/inventory/Ansible_Doc_Ping_Module_Arguments_Inventory_Study_Notes.md" \
          "$repo/study-notes/english/06-ad-hoc-commands/ansible-doc-ping-and-inventory.md"
safe_move "$repo/study-notes/english/labs/Ansible_Common_Modules_Arguments_Quick_Reference.md" \
          "$repo/study-notes/english/07-modules/ansible-common-modules-quick-reference.md"
safe_move "$repo/study-notes/english/labs/Ansible_Hands_On_Lab_Master_Study_Notes.md" \
          "$repo/exercises/guided-labs/ansible-hands-on-lab-master.md"

# Move Roman Urdu notes into their matching topic directories.
safe_move "$repo/study-notes/urdu-roman/Ansible_Control_Node_Setup_Rocky_Linux_9_Roman_Urdu.md" \
          "$repo/study-notes/roman-urdu/02-control-node-setup/ansible-control-node-setup-rocky-linux-9.md"
safe_move "$repo/study-notes/urdu-roman/SSH_Custom_Key_Filename_Ansible_Study_Notes_roman_Urdu.md" \
          "$repo/study-notes/roman-urdu/03-ssh/ssh-custom-key-filename.md"
safe_move "$repo/study-notes/urdu-roman/configuration/Ansible_Config_Study_Notes_Roman_Urdu.md" \
          "$repo/study-notes/roman-urdu/04-configuration/ansible-config.md"
safe_move "$repo/study-notes/urdu-roman/Ansible_Project_Directory_and_Config_Study_Notes_Roman_Urdu.md" \
          "$repo/study-notes/roman-urdu/05-inventory/ansible-project-directory-and-config.md"
safe_move "$repo/study-notes/english/labs/Ansible_Common_Modules_Arguments_Quick_Reference_roman_Urdu.md" \
          "$repo/study-notes/roman-urdu/07-modules/ansible-common-modules-quick-reference.md"
safe_move "$repo/study-notes/urdu-roman/labs/Ansible_Hands_On_Lab_Master_Study_Notes_Roman_Urdu.md" \
          "$repo/exercises/guided-labs/ansible-hands-on-lab-master-roman-urdu.md"

# Move the existing Nginx project material.
safe_move "$repo/labs/problems/Deploy-Static-Website-with-NGINX-Rocky-Linux-Study-Notes.md" \
          "$repo/projects/01-deploy-nginx/README.md"

# Correct the misspelled Bash prompt directory without overwriting anything.
if [[ -d "$repo/misc/colered-username-hostname" ]]; then
    mkdir -p -- "$repo/resources/bash-prompt-customization"
    move_directory_contents "$repo/misc/colered-username-hostname" \
                            "$repo/resources/bash-prompt-customization"
fi

# Move the SCP note into the SSH troubleshooting section.
safe_move "$repo/misc/scp/SCP-Linux-VM-to-Windows-Study-Notes.md" \
          "$repo/troubleshooting/ssh/scp-linux-vm-to-windows.md"

# Create starter files only when they do not already exist.
if [[ ! -e "$repo/requirements.yml" ]]; then
    printf '%s\n' '---' 'collections: []' > "$repo/requirements.yml"
    echo "CREATED: requirements.yml"
fi

if [[ ! -e "$repo/inventories/lab/group_vars/all.yml" ]]; then
    printf '%s\n' \
        '---' \
        'ansible_user: ansibleadmin' \
        'ansible_python_interpreter: /usr/bin/python3' \
        > "$repo/inventories/lab/group_vars/all.yml"
    echo "CREATED: inventories/lab/group_vars/all.yml"
fi

# Keep intentionally empty directories visible to Git.
for directory in "${directories[@]}"; do
    if [[ -z $(find "$repo/$directory" -mindepth 1 -maxdepth 1 -print -quit) ]]; then
        : > "$repo/$directory/.gitkeep"
    fi
done

# Remove only old directories that are completely empty. No files are deleted.
find "$repo/automation" "$repo/labs" "$repo/misc" \
    -depth -type d -empty -delete 2>/dev/null || true

echo
echo "Reorganization completed successfully."
echo "Backup: $backup_file"
echo
echo "Recommended checks:"
echo "  cd '$repo'"
echo "  find . -maxdepth 3 -path './.git' -prune -o -print | sort"
echo "  git status --short"
echo "  ansible-config dump --only-changed"
echo "  ansible-inventory --graph"
