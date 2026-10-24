# Windows-to-Windows SSH and SCP: From Scratch

Study notes based on our successful home-network transfer — 3 October 2026.

## Index

1. [Goal and basic concepts](#1-goal-and-basic-concepts)
2. [Our network](#2-our-network)
3. [Check IP addresses and gateways](#3-check-ip-addresses-and-gateways)
4. [Check the SSH client](#4-check-the-ssh-client)
5. [Test desktop SSH connectivity](#5-test-desktop-ssh-connectivity)
6. [Install and enable the desktop SSH server](#6-install-and-enable-the-desktop-ssh-server)
7. [Allow SSH through the firewall](#7-allow-ssh-through-the-firewall)
8. [Connect and understand the host key](#8-connect-and-understand-the-host-key)
9. [Fix authentication: our separate transfer account](#9-fix-authentication-our-separate-transfer-account)
10. [Copy files and folders](#10-copy-files-and-folders)
11. [Our successful transfer](#11-our-successful-transfer)
12. [Verify the copied files](#12-verify-the-copied-files)
13. [Troubleshooting](#13-troubleshooting)
14. [Quick reference and practice answers](#14-quick-reference-and-practice-answers)

## 1. Goal and basic concepts

**Goal:** Copy files and folders from a Windows laptop to a Windows desktop at home using an encrypted SSH connection.

| Term | Meaning | Analogy |
|---|---|---|
| IP address | Identifies a network interface | A house address |
| Subnet mask | Defines which addresses are in the local subnet | The neighborhood boundary |
| Default gateway | Router used to reach other networks | The neighborhood exit |
| Port | Identifies a network service | A particular door |
| SSH | Secure remote login protocol | An encrypted connection to the other computer |
| SCP | File-copy tool that uses SSH | Carrying files over that secure connection |
| SSH client | Starts the connection | The visitor |
| SSH server (`sshd`) | Receives the connection | The receiving service |

Modern OpenSSH SCP typically uses SFTP for the actual file-transfer protocol, over SSH. You still run the `scp` command.

The laptop needs an SSH client. The desktop needs an SSH server. For this workflow, the laptop does not need an SSH server—even when you pull a file back from the desktop.

## 2. Our network

| Device or adapter | IPv4 address | Mask / subnet | Gateway | Role |
|---|---|---|---|---|
| Laptop Wi-Fi | `10.0.0.8` | `255.255.255.0` / `10.0.0.0/24` | `10.0.0.1` | Source machine |
| Desktop Ethernet | `10.0.0.213` | `255.255.255.0` / `10.0.0.0/24` | `10.0.0.1` | Destination machine |
| Laptop other adapter | `10.8.0.3` | `/24` | None shown | Likely VPN; not used for this transfer |
| Desktop VMware VMnet1 | `192.168.38.1` | `/24` | None shown | VMware virtual network |
| Desktop VMware VMnet8 | `192.168.23.1` | `/24` | None shown | VMware virtual network |

**Conclusion:** Laptop and desktop share the same IPv4 subnet. Use the desktop's Ethernet address, `10.0.0.213`.

Wi-Fi on one computer and Ethernet on the other is fine when the router permits communication between them. Same-subnet traffic normally travels locally through the router's access point/switch; it does not need the internet or default-gateway routing. Guest Wi-Fi or client isolation can prevent this communication.

The VMware adapter addresses are not the desktop's home-LAN destination addresses. DHCP addresses may change later, so check again if a previously working command stops working.

## 3. Check IP addresses and gateways

**WHY:** Identify the correct source and destination before troubleshooting services.

**WHERE:** Normal PowerShell on both computers.

```powershell
ipconfig
```

On the laptop, read the connected Wi-Fi adapter. On the desktop, read the connected Ethernet adapter. Record IPv4 address, subnet mask, and default gateway. Ignore disconnected adapters for this task.

**NEXT:** Test the desktop's SSH port using its confirmed LAN address.

## 4. Check the SSH client

**WHERE:** Laptop PowerShell.

```powershell
Get-Command ssh, scp
ssh -V
```

If the commands are missing, open laptop PowerShell as Administrator and install the client:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

In our session, both commands were already available.

## 5. Test desktop SSH connectivity

**WHY:** Being on the same subnet does not mean the SSH service is ready.

**WHERE:** Laptop PowerShell.

```powershell
Test-NetConnection 10.0.0.213 -Port 22
```

Our first result was `TcpTestSucceeded : False`. This meant TCP port 22 was unreachable; it did not identify a single cause. Possible causes included a missing/stopped SSH server, firewall filtering, or network isolation.

After desktop setup, our result became:

```text
RemoteAddress    : 10.0.0.213
RemotePort       : 22
InterfaceAlias   : Wi-Fi
SourceAddress    : 10.0.0.8
TcpTestSucceeded : True
```

**Interpretation:** The laptop successfully reached TCP port 22 on the desktop. Login credentials still need to be accepted.

### Why ping failed while SSH worked

Ping uses ICMP echo requests. SSH uses TCP port 22. Firewall rules can permit one and block the other. Our ping timed out, but SSH and SCP worked; enabling ping was unnecessary for this transfer.

Windows ping count syntax:

```powershell
ping -n 2 10.0.0.213
```

Linux uses `ping -c 2`. Windows interprets `-c` differently; it is not the Windows packet-count option. Running as Administrator is not the fix for that syntax mistake.

## 6. Install and enable the desktop SSH server

**WHY:** The desktop must listen for incoming SSH connections.

**WHERE:** Desktop PowerShell, **Run as administrator**.

Check installation:

```powershell
Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

If `State` is `NotPresent`, install it:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

Start it and enable automatic startup:

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Get-Service sshd
```

Expected service status: `Running`.

If Windows reports a restart is required, restart before continuing. If installation or service startup fails, address that error first.

## 7. Allow SSH through the firewall

**WHY:** A running service also needs an allowed incoming connection.

**WHERE:** Desktop Administrator PowerShell.

The installer normally creates the OpenSSH firewall rule. Enable it if present, or create it if absent:

```powershell
if (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue) {
    Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Enabled True
} else {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
}
```

Keep Windows Firewall enabled. No router port forwarding is needed for this local home-network transfer.

**NEXT:** Repeat `Test-NetConnection 10.0.0.213 -Port 22` on the laptop.

## 8. Connect and understand the host key

**WHERE:** Laptop PowerShell.

Our initial attempt:

```powershell
ssh krmar@10.0.0.213
```

The first connection showed an authenticity prompt with an ED25519 fingerprint. This is the server's identity key, not the user's password.

For a new connection, verify the fingerprint on the desktop before accepting it. On the desktop:

```powershell
ssh-keygen -lf C:\ProgramData\ssh\ssh_host_ed25519_key.pub
```

Compare its SHA256 fingerprint with the laptop's prompt. If it matches, enter `yes`. SSH records it in the laptop user's `.ssh\known_hosts` file. If a previously known key changes unexpectedly, investigate rather than blindly removing it.

Then enter the destination account's password. Password characters are not displayed while typing. A Windows Hello PIN is not the account password used by SSH password authentication.

## 9. Fix authentication: our separate transfer account

Our connection reached the server, but login as `krmar` produced:

```text
Permission denied, please try again.
```

The desktop account password was forgotten. We used a separate local account named `filetransfer` with a new password. This did not reset the existing account password.

**Prerequisite:** You can open an elevated PowerShell session on the desktop. These commands require administrator access.

**WHERE:** Desktop Administrator PowerShell. Run once to create a new account:

```powershell
$password = Read-Host "Enter a new password for filetransfer" -AsSecureString
New-LocalUser -Name "filetransfer" -Password $password -Description "Home SSH file transfers"
Add-LocalGroupMember -SID "S-1-5-32-545" -Member "filetransfer"
```

The SID identifies the built-in Users group, including on Windows installations with a different display language. This creates a standard user, not an administrator. If the account already exists, do not rerun the creation command.

On the laptop:

```powershell
ssh filetransfer@10.0.0.213
```

Enter the new password. Inside the desktop SSH session, create the destination folder:

```cmd
mkdir C:\Users\filetransfer\Transfers
exit
```

`exit` returns you to the laptop shell. The account needs write permission to the destination; its own profile folder is the straightforward choice.

## 10. Copy files and folders

**WHERE:** Laptop PowerShell, outside the remote SSH session.

General syntax:

```text
scp [options] source destination
```

### Send one file

From the directory containing `notes.txt`:

```powershell
scp .\notes.txt filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/
```

### Send a folder

```powershell
scp -r .\vmware filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/
```

`-r` means recursive: copy the folder and its contents, including subfolders.

### Paths containing spaces

Quote the entire argument containing spaces:

```powershell
scp ".\01 LabSetup.pdf" "filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/"
```

### Pull a desktop file back to the laptop

```powershell
scp filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/notes.txt .
```

The final `.` means the current local directory. You are still starting the connection from the laptop, so only the desktop needs the SSH server.

### Pull a folder back

Use a separate local destination to avoid mixing files with the original source:

```powershell
New-Item -ItemType Directory -Path .\received -Force
scp -r filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/vmware .\received\
```

### Useful options

| Option | Purpose | Example |
|---|---|---|
| `-r` | Copy a directory recursively | `scp -r .\vmware user@host:C:/destination/` |
| `-v` | Show connection diagnostics | `scp -v .\notes.txt user@host:C:/destination/` |
| `-P 2222` | Use a custom SSH port; uppercase P | `scp -P 2222 .\notes.txt user@host:C:/destination/` |
| `-i` | Specify an SSH private key | `scp -i "$env:USERPROFILE\.ssh\id_ed25519" .\notes.txt user@host:C:/destination/` |

For `ssh`, the custom-port option is lowercase `-p`. Only use a custom port or key when the server/account is configured for it.

SCP can overwrite files with matching destination names. It is a copy tool, not an incremental synchronization or automatic resume tool.

## 11. Our successful transfer

**Laptop prompt:** `PS C:\Linux>`

**Command used:**

```powershell
scp -r .\vmware filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/
```

| Part | Meaning |
|---|---|
| `scp` | Start an SSH file transfer |
| `-r` | Include the directory tree |
| `.\vmware` | Source folder: `C:\Linux\vmware` |
| `filetransfer` | Desktop login account |
| `10.0.0.213` | Desktop LAN address |
| `:` | Separates the remote host from its path |
| `C:/Users/filetransfer/Transfers/` | Desktop destination directory |

**Resulting folder on desktop:**

```text
C:\Users\filetransfer\Transfers\vmware
```

The output showed files reaching `100%`, including large ISO images, and returned to `PS C:\Linux>` without a reported error. This demonstrated successful Wi-Fi-to-Ethernet transfer over the home LAN.

The empty archive listed as `0` bytes was accepted as-is. `100%` for an empty file does not mean it contains data.

## 12. Verify the copied files

Immediately after SCP finishes, check its exit status in laptop PowerShell:

```powershell
$LASTEXITCODE
```

`0` means the command reported success. Check before running another native executable, which may replace this value.

On the desktop, inspect the destination in File Explorer or PowerShell:

```powershell
Get-ChildItem C:\Users\filetransfer\Transfers\vmware
```

For an important ISO, compare SHA256 hashes of the source and destination. Choose the same file on each computer:

**Laptop:**

```powershell
Get-FileHash "C:\Linux\vmware\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso" -Algorithm SHA256
```

**Desktop:**

```powershell
Get-FileHash "C:\Users\filetransfer\Transfers\vmware\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso" -Algorithm SHA256
```

If the ISO is inside a subfolder, adjust both paths. Matching hashes verify that these two file copies have the same content. To verify download authenticity, separately compare against the software publisher's official checksum.

## 13. Troubleshooting

| Symptom | What it means / next check |
|---|---|
| `ssh` or `scp` is not recognized | Check/install OpenSSH Client on the laptop |
| `TcpTestSucceeded : False` | Confirm current IP, desktop awake, `sshd` running, firewall rule, and network isolation |
| Ping fails but TCP succeeds | ICMP may be filtered; continue with SSH |
| Host authenticity prompt | Verify the desktop host fingerprint before accepting |
| `Permission denied` at password prompt | Check destination username and account password; PIN is different |
| No password characters appear | Normal terminal behavior |
| `No such file or directory` | Check source path, current directory, and destination folder |
| Permission denied writing a file | Use a folder writable by the SSH account |
| Transfer interrupted | Check connectivity/disk space; SCP normally restarts that file when rerun |
| VMware adapter IP times out | Use the desktop LAN IP for this workflow |
| Previously working IP stops responding | Check `ipconfig` again; DHCP may have assigned another address |

Useful desktop checks, in Administrator PowerShell:

```powershell
Get-Service sshd
Get-NetTCPConnection -State Listen -LocalPort 22
Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP"
```

## 14. Quick reference and practice answers

### Our sequence

1. Check `ipconfig` on both PCs.
2. Identify connected Wi-Fi/Ethernet addresses, masks, and gateways.
3. Choose desktop LAN IP `10.0.0.213`.
4. Test TCP port 22 from the laptop.
5. Install/start desktop OpenSSH Server and enable its firewall rule.
6. Retest until TCP succeeds.
7. Connect with SSH and verify the host identity.
8. Resolve account authentication using the `filetransfer` account.
9. Create a writable destination folder.
10. Run SCP from the laptop.
11. Check completion and verify important files.

### Practice questions with answers

| Question | Answer |
|---|---|
| Which desktop IP did we use? | `10.0.0.213`, its Ethernet LAN address |
| Why did we check the subnet mask? | To determine whether both IPv4 addresses are in the same subnet |
| Must both PCs use Wi-Fi? | No; Wi-Fi and Ethernet can communicate on the home LAN |
| Does local SCP need internet access? | No, once the required software is installed |
| Does local SCP need router port forwarding? | No |
| What service receives SSH connections? | `sshd` on the desktop |
| What is the default SSH port? | TCP 22 |
| Does TCP success prove the password is correct? | No; connection and authentication are separate checks |
| Why did ping failure not stop us? | Ping and SSH use different protocols and firewall rules |
| What does `-r` do? | Copies a directory and its contents recursively |
| What does `.\vmware` mean? | The vmware folder under the current local directory |
| What does the last `.` in a pull command mean? | Save into the current local directory |
| Do we use the laptop password? | No; use the destination desktop account's credentials |
| Does a Windows Hello PIN work as an SSH password? | No |
| Does copying delete the source? | No |
| Can matching destination files be overwritten? | Yes |

### Official references

- [Microsoft: Install and start OpenSSH for Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)
- [Microsoft: Troubleshoot OpenSSH and Windows Firewall](https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/troubleshoot-openssh-windows-firewall-port22)
- [Microsoft: Test-NetConnection](https://learn.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection)
- [OpenSSH: scp manual](https://man.openbsd.org/scp)

These notes record our actual successful setup and add verification steps for future practice. They do not change either computer's configuration by themselves.
