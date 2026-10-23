# SCP: Copy Files Between a Linux VM and Windows

## Lab Environment

| System | Address or path |
|---|---|
| Windows laptop | `C:\Users\krmar` |
| Ansible control node | `192.168.1.233` |
| Linux account | `ansibleadmin` |
| Remote inventory file | `/home/ansibleadmin/automation/inventory/nodes` |
| Windows destination | `C:\Users\krmar\Downloads` |

## What is SCP?

`scp` means **Secure Copy Protocol**. It copies files and directories between systems through an encrypted SSH connection.

Because SCP uses SSH:

- The destination VM must be reachable through the network or VPN.
- The SSH service must be running on the VM.
- The user must have permission to read the source file or write to the destination directory.
- SSH keys can provide passwordless authentication.

## Successful Lab Command

The following commands were run in Windows PowerShell:

```powershell
cd C:\Users\krmar\Downloads\
scp ansibleadmin@192.168.1.233:/home/ansibleadmin/automation/inventory/nodes .
```

Output:

```text
nodes    100% 1158    5.8KB/s    00:00
```

This confirms that the `nodes` file was copied successfully from the Linux VM to the current Windows directory.

## Command Breakdown

```powershell
scp ansibleadmin@192.168.1.233:/home/ansibleadmin/automation/inventory/nodes .
```

| Part | Meaning |
|---|---|
| `scp` | Starts the secure-copy program. |
| `ansibleadmin` | Account used to log in to the Linux VM. |
| `@` | Separates the remote username from the host address. |
| `192.168.1.233` | IP address of the Ansible control node. |
| `:` | Separates the remote host from the remote path. |
| `/home/ansibleadmin/automation/inventory/nodes` | Source file on the Linux VM. |
| `.` | Current directory on the Windows laptop. |

At the time of execution, the current Windows directory was:

```text
C:\Users\krmar\Downloads
```

Therefore, the downloaded file became:

```text
C:\Users\krmar\Downloads\nodes
```

## Understanding the Progress Output

```text
nodes    100% 1158    5.8KB/s    00:00
```

| Field | Meaning |
|---|---|
| `nodes` | Name of the file being transferred. |
| `100%` | The complete file was transferred. |
| `1158` | Approximate number of bytes transferred. |
| `5.8KB/s` | Transfer speed. |
| `00:00` | Transfer duration. |

## General Download Syntax

To copy a file from a Linux VM to Windows:

```powershell
scp username@VM_IP:/remote/source/path "C:\local\destination\"
```

Example:

```powershell
scp ansibleadmin@192.168.1.190:/home/ansibleadmin/notes.txt "$HOME\Downloads\"
```

Here, PowerShell expands `$HOME` to the current Windows user's home directory, such as:

```text
C:\Users\krmar
```

## Download and Rename a File

Specify a new filename at the destination:

```powershell
scp ansibleadmin@192.168.1.233:/home/ansibleadmin/automation/inventory/nodes "$HOME\Downloads\ansible-nodes.ini"
```

## Download an Entire Directory

Use `-r` for a recursive directory copy:

```powershell
scp -r ansibleadmin@192.168.1.233:/home/ansibleadmin/automation "$HOME\Downloads\"
```

Without `-r`, SCP cannot copy a directory.

## Upload a File from Windows to the VM

Reverse the source and destination:

```powershell
scp "$HOME\Downloads\nodes" ansibleadmin@192.168.1.233:/home/ansibleadmin/
```

The main patterns are:

```text
Download: scp remote-source local-destination
Upload:   scp local-source remote-destination
```

## Verify the Download on Windows

Display file information:

```powershell
Get-Item .\nodes
```

Read the file:

```powershell
Get-Content .\nodes
```

Open it in Notepad:

```powershell
notepad .\nodes
```

Calculate a checksum:

```powershell
Get-FileHash .\nodes -Algorithm SHA256
```

## Verify the Remote File Before Copying

```powershell
ssh ansibleadmin@192.168.1.233 "ls -lh /home/ansibleadmin/automation/inventory/nodes"
```

## Copy Using a Hostname

If the Windows laptop can resolve the hostname through DNS or its Windows hosts file:

```powershell
scp ansibleadmin@ansible-server.nitclasses.com:/home/ansibleadmin/automation/inventory/nodes .
```

Using the IP address is appropriate when hostname resolution has not been configured on Windows.

## Custom SSH Port

For SCP, uppercase `-P` specifies a non-default SSH port:

```powershell
scp -P 2222 ansibleadmin@192.168.1.233:/home/ansibleadmin/file.txt .
```

Important distinction:

```text
ssh -p 2222 ...   # lowercase -p
scp -P 2222 ...   # uppercase -P
```

## Copy a File That Requires Root Permission

SCP runs with the permissions of `ansibleadmin`; it does not automatically use `sudo`.

First create a readable temporary copy on the VM:

```powershell
ssh ansibleadmin@192.168.1.233 "sudo cp /etc/ssh/sshd_config /home/ansibleadmin/sshd_config.copy; sudo chown ansibleadmin:ansibleadmin /home/ansibleadmin/sshd_config.copy"
```

Download it:

```powershell
scp ansibleadmin@192.168.1.233:/home/ansibleadmin/sshd_config.copy "$HOME\Downloads\"
```

Remove the temporary remote copy:

```powershell
ssh ansibleadmin@192.168.1.233 "rm /home/ansibleadmin/sshd_config.copy"
```

## Common Errors

### No such file or directory

```text
scp: /path/file: No such file or directory
```

Verify the remote path:

```powershell
ssh ansibleadmin@192.168.1.233 "ls -l /path/file"
```

### Permission denied while reading

The remote user cannot read the source file. Check it with:

```powershell
ssh ansibleadmin@192.168.1.233 "ls -l /remote/file"
```

### Permission denied while writing

The user cannot write to the remote destination. Upload to the user's home directory first, then move it with `sudo` after reviewing the file.

### Connection timed out

Possible causes include:

- VPN is disconnected.
- The VM is powered off.
- The IP address is incorrect.
- Port 22 is blocked by a firewall.
- The SSH service is not running.

Useful tests:

```powershell
Test-NetConnection 192.168.1.233 -Port 22
ssh ansibleadmin@192.168.1.233
```

### Hostname cannot be resolved

Use the IP address or configure DNS/the Windows hosts file.

## Security Notes

- SCP encrypts the file and authentication traffic through SSH.
- SSH key authentication is safer and more convenient than putting passwords in commands.
- Never place an account password directly in an SCP command.
- Confirm the remote host key before accepting it.
- Copy protected system files only when required and remove temporary copies afterward.

## Quick Reference

```powershell
# Download one file
scp ansibleadmin@192.168.1.233:/remote/file "$HOME\Downloads\"

# Download one file to the current directory
scp ansibleadmin@192.168.1.233:/remote/file .

# Download a directory
scp -r ansibleadmin@192.168.1.233:/remote/directory "$HOME\Downloads\"

# Upload one file
scp "$HOME\Downloads\file.txt" ansibleadmin@192.168.1.233:/home/ansibleadmin/

# Use a custom SSH port
scp -P 2222 ansibleadmin@192.168.1.233:/remote/file .
```

## Interview Answer

> I use SCP to securely copy files between Linux and another system over SSH. To download a file, I specify the remote user, host and source path followed by the local destination. I use `-r` when copying a directory and uppercase `-P` when the SSH server uses a custom port. Before transferring protected files, I verify permissions rather than bypassing security controls. I also verify the copied file and use SSH key authentication when appropriate.
