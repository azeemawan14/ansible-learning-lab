# Windows se Windows SSH aur SCP: Bilkul Shuru Se

Hamare kamyab home-network file transfer par mabni study notes — 3 October 2026.

## Index

1. [Maqsad aur bunyadi concepts](#1-maqsad-aur-bunyadi-concepts)
2. [Hamara network](#2-hamara-network)
3. [IP addresses aur gateways check karein](#3-ip-addresses-aur-gateways-check-karein)
4. [SSH client check karein](#4-ssh-client-check-karein)
5. [Desktop ki SSH connectivity test karein](#5-desktop-ki-ssh-connectivity-test-karein)
6. [Desktop par SSH server install aur enable karein](#6-desktop-par-ssh-server-install-aur-enable-karein)
7. [Firewall mein SSH allow karein](#7-firewall-mein-ssh-allow-karein)
8. [Connect karein aur host key samjhein](#8-connect-karein-aur-host-key-samjhein)
9. [Authentication ka masla aur alag transfer account](#9-authentication-ka-masla-aur-alag-transfer-account)
10. [Files aur folders copy karein](#10-files-aur-folders-copy-karein)
11. [Hamara kamyab transfer](#11-hamara-kamyab-transfer)
12. [Copy hui files verify karein](#12-copy-hui-files-verify-karein)
13. [Troubleshooting](#13-troubleshooting)
14. [Quick reference aur practice jawabat](#14-quick-reference-aur-practice-jawabat)

## 1. Maqsad aur bunyadi concepts

**Maqsad:** Ghar mein Windows laptop se Windows desktop par encrypted SSH connection ke zariye files aur folders copy karna.

| Term | Matlab | Misaal |
|---|---|---|
| IP address | Network interface ki pehchan karta hai | Ghar ka pata |
| Subnet mask | Batata hai ke kaun se addresses local subnet mein hain | Mohallay ki boundary |
| Default gateway | Doosre networks tak pohanchne ke liye istemal hone wala router | Mohallay se bahar nikalne ka rasta |
| Port | Network service ki pehchan karta hai | Ek khaas darwaza |
| SSH | Mehfooz remote login ka protocol | Doosre computer tak encrypted connection |
| SCP | SSH istemal karne wala file-copy tool | Mehfooz connection par files le jana |
| SSH client | Connection shuru karta hai | Milne aane wala shakhs |
| SSH server (`sshd`) | Connection receive karta hai | Connection qabool karne wali service |

Modern OpenSSH SCP aam tor par asal file transfer ke liye SSH ke upar SFTP protocol istemal karta hai. Command phir bhi `scp` hi hoti hai.

Laptop ko SSH client chahiye aur desktop ko SSH server. Is tareeqay mein laptop par SSH server zaroori nahi, chahe aap desktop se file wapas laptop par mangwa rahe hon.

## 2. Hamara network

| Device ya adapter | IPv4 address | Mask / subnet | Gateway | Kirdar |
|---|---|---|---|---|
| Laptop Wi-Fi | `10.0.0.8` | `255.255.255.0` / `10.0.0.0/24` | `10.0.0.1` | Source machine |
| Desktop Ethernet | `10.0.0.213` | `255.255.255.0` / `10.0.0.0/24` | `10.0.0.1` | Destination machine |
| Laptop ka doosra adapter | `10.8.0.3` | `/24` | Nazar nahi aaya | Mumkin hai VPN ho; is transfer mein istemal nahi hua |
| Desktop VMware VMnet1 | `192.168.38.1` | `/24` | Nazar nahi aaya | VMware virtual network |
| Desktop VMware VMnet8 | `192.168.23.1` | `/24` | Nazar nahi aaya | VMware virtual network |

**Nateeja:** Laptop aur desktop ek hi IPv4 subnet mein hain. Desktop ka Ethernet address `10.0.0.213` istemal karein.

Ek computer ka Wi-Fi aur doosre ka Ethernet par hona theek hai, agar router dono ko aapas mein communicate karne deta ho. Ek hi subnet ka traffic aam tor par router ke access point/switch se local tor par guzarta hai. Isay internet ya default gateway ki routing ki zaroorat nahi hoti. Guest Wi-Fi ya client isolation is communication ko rok sakta hai.

VMware adapters ke addresses desktop ke home-LAN destination addresses nahi hain. DHCP addresses baad mein badal sakte hain. Agar pehle chalne wali command band ho jaye to IP dobara check karein.

## 3. IP addresses aur gateways check karein

**KYUN:** Services ka masla check karne se pehle sahi source aur destination pehchanna zaroori hai.

**KAHAN:** Dono computers par normal PowerShell.

```powershell
ipconfig
```

Laptop par connected Wi-Fi adapter aur desktop par connected Ethernet adapter dekhein. IPv4 address, subnet mask aur default gateway note karein. Is kaam ke liye disconnected adapters ko nazarandaz karein.

**AGLA QADAM:** Desktop ke tasdeeq-shuda LAN address par SSH port test karein.

## 4. SSH client check karein

**KAHAN:** Laptop PowerShell.

```powershell
Get-Command ssh, scp
ssh -V
```

Agar commands mojood nahi hain to laptop par PowerShell **Run as administrator** kholein aur client install karein:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

Hamare session mein dono commands pehle se mojood thin.

## 5. Desktop ki SSH connectivity test karein

**KYUN:** Ek hi subnet mein hone ka matlab yeh nahi ke SSH service bhi tayyar hai.

**KAHAN:** Laptop PowerShell.

```powershell
Test-NetConnection 10.0.0.213 -Port 22
```

Hamara pehla result `TcpTestSucceeded : False` tha. Is ka matlab TCP port 22 tak connection nahi pohanch raha tha; is se kisi ek wajah ki tasdeeq nahi hoti. Mumkin wajuhat mein SSH server ka install na hona ya band hona, firewall filtering aur network isolation shamil thin.

Desktop setup ke baad result yeh hua:

```text
RemoteAddress    : 10.0.0.213
RemotePort       : 22
InterfaceAlias   : Wi-Fi
SourceAddress    : 10.0.0.8
TcpTestSucceeded : True
```

**Matlab:** Laptop desktop ke TCP port 22 tak kamyabi se pohanch gaya. Abhi login credentials ka qabool hona baqi hai.

### Ping fail hua magar SSH kyun chala?

Ping ICMP echo requests istemal karta hai. SSH TCP port 22 istemal karta hai. Firewall ek ko allow aur doosre ko block kar sakta hai. Hamara ping timeout hua, lekin SSH aur SCP chal gaye. Is transfer ke liye ping enable karna zaroori nahi tha.

Windows mein ping ki tadaad dene ka syntax:

```powershell
ping -n 2 10.0.0.213
```

Linux mein `ping -c 2` hota hai. Windows mein `-c` ka matlab mukhtalif hai; yeh packet count ka option nahi. Administrator ke tor par chalana is ghalat syntax ka hal nahi hai.

## 6. Desktop par SSH server install aur enable karein

**KYUN:** Desktop ko aane wale SSH connections ke liye listen karna hota hai.

**KAHAN:** Desktop PowerShell, **Run as administrator**.

Installation check karein:

```powershell
Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

Agar `State` mein `NotPresent` ho to install karein:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

Service start karein aur automatic startup enable karein:

```powershell
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
Get-Service sshd
```

Expected service status: `Running`.

Agar Windows restart karne ko kahe to aage barhne se pehle restart karein. Installation ya service startup fail ho to pehle us error ko hal karein.

## 7. Firewall mein SSH allow karein

**KYUN:** Service chalne ke saath incoming connection ka allowed hona bhi zaroori hai.

**KAHAN:** Desktop Administrator PowerShell.

Installer aam tor par OpenSSH firewall rule bana deta hai. Agar rule mojood ho to enable karein, warna naya banayein:

```powershell
if (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue) {
    Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Enabled True
} else {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow
}
```

Windows Firewall enabled rakhein. Local home-network transfer ke liye router par port forwarding ki zaroorat nahi.

**AGLA QADAM:** Laptop par `Test-NetConnection 10.0.0.213 -Port 22` dobara chalayein.

## 8. Connect karein aur host key samjhein

**KAHAN:** Laptop PowerShell.

Hamari pehli koshish:

```powershell
ssh krmar@10.0.0.213
```

Pehle connection par authenticity prompt mein ED25519 fingerprint nazar aaya. Yeh server ki identity key hai, user ka password nahi.

Naye connection ko accept karne se pehle desktop par fingerprint verify karein:

```powershell
ssh-keygen -lf C:\ProgramData\ssh\ssh_host_ed25519_key.pub
```

Is ka SHA256 fingerprint laptop ke prompt se milayein. Agar match kare to `yes` likhein. SSH isay laptop user ki `.ssh\known_hosts` file mein record karta hai. Agar pehle se known key achanak badal jaye to wajah check karein; baghair jaanch ke key remove na karein.

Phir destination account ka password dein. Password type karte waqt characters nazar nahi aate. Windows Hello PIN, SSH password authentication mein istemal hone wala account password nahi hai.

## 9. Authentication ka masla aur alag transfer account

Hamara connection server tak pohanch gaya tha, magar `krmar` se login par yeh aaya:

```text
Permission denied, please try again.
```

Desktop account ka password yaad nahi tha. Hum ne `filetransfer` naam ka alag local account naye password ke saath banaya. Is se mojooda account ka password reset nahi hua.

**Zaroori shart:** Desktop par elevated PowerShell kholne ki access honi chahiye. In commands ko administrator access chahiye.

**KAHAN:** Desktop Administrator PowerShell. Naya account banane ke liye ek martaba chalayein:

```powershell
$password = Read-Host "Enter a new password for filetransfer" -AsSecureString
New-LocalUser -Name "filetransfer" -Password $password -Description "Home SSH file transfers"
Add-LocalGroupMember -SID "S-1-5-32-545" -Member "filetransfer"
```

Yeh SID built-in Users group ki pehchan karta hai, chahe Windows ki display language mukhtalif ho. Yeh standard user banata hai, administrator nahi. Agar account pehle se mojood ho to creation command dobara na chalayein.

Laptop par:

```powershell
ssh filetransfer@10.0.0.213
```

Naya password dein. Desktop ke SSH session ke andar destination folder banayein:

```cmd
mkdir C:\Users\filetransfer\Transfers
exit
```

`exit` aap ko laptop ke shell mein wapas lata hai. Account ko destination par write permission chahiye; us ka apna profile folder seedha aur asaan intikhab hai.

## 10. Files aur folders copy karein

**KAHAN:** Laptop PowerShell, remote SSH session se bahar.

Aam syntax:

```text
scp [options] source destination
```

### Ek file bhejein

Us directory se jahan `notes.txt` mojood hai:

```powershell
scp .\notes.txt filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/
```

### Folder bhejein

```powershell
scp -r .\vmware filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/
```

`-r` ka matlab recursive hai: folder aur us ke tamam contents, subfolders samait, copy karna.

### Path mein spaces hon

Spaces wale poore argument ko quotes mein rakhein:

```powershell
scp ".\01 LabSetup.pdf" "filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/"
```

### Desktop se file laptop par wapas mangwayein

```powershell
scp filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/notes.txt .
```

Aakhir ka `.` current local directory ko zahir karta hai. Connection ab bhi laptop se shuru ho raha hai, is liye sirf desktop ko SSH server chahiye.

### Folder wapas mangwayein

Asal source files ke saath files mix hone se bachane ke liye alag local destination banayein:

```powershell
New-Item -ItemType Directory -Path .\received -Force
scp -r filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/vmware .\received\
```

### Kaam ke options

| Option | Maqsad | Misaal |
|---|---|---|
| `-r` | Directory ko subfolders samait copy karna | `scp -r .\vmware user@host:C:/destination/` |
| `-v` | Connection ki diagnostic details dikhana | `scp -v .\notes.txt user@host:C:/destination/` |
| `-P 2222` | Custom SSH port; bara P | `scp -P 2222 .\notes.txt user@host:C:/destination/` |
| `-i` | SSH private key specify karna | `scp -i "$env:USERPROFILE\.ssh\id_ed25519" .\notes.txt user@host:C:/destination/` |

`ssh` mein custom port ke liye chhota `-p` hota hai. Custom port ya key tabhi istemal karein jab server/account us ke liye configured ho.

SCP destination par same naam ki files overwrite kar sakta hai. Yeh copy tool hai; incremental synchronization ya automatic resume ka tool nahi.

## 11. Hamara kamyab transfer

**Laptop prompt:** `PS C:\Linux>`

**Istemaal ki gayi command:**

```powershell
scp -r .\vmware filetransfer@10.0.0.213:C:/Users/filetransfer/Transfers/
```

| Hissa | Matlab |
|---|---|
| `scp` | SSH ke zariye file transfer shuru karna |
| `-r` | Poori directory tree shamil karna |
| `.\vmware` | Source folder: `C:\Linux\vmware` |
| `filetransfer` | Desktop ka login account |
| `10.0.0.213` | Desktop ka LAN address |
| `:` | Remote host aur us ke path ko alag karta hai |
| `C:/Users/filetransfer/Transfers/` | Desktop ki destination directory |

**Desktop par banne wala folder:**

```text
C:\Users\filetransfer\Transfers\vmware
```

Output mein bari ISO images samait files `100%` tak pohanchin aur baghair reported error ke `PS C:\Linux>` prompt wapas aa gaya. Is se home LAN par Wi-Fi se Ethernet tak kamyab transfer zahir hua.

`0` bytes wali khali archive jaisi thi waisi hi qabool hui. Khali file ke liye `100%` ka matlab yeh nahi ke us mein data mojood hai.

## 12. Copy hui files verify karein

SCP khatam hote hi laptop PowerShell mein exit status check karein:

```powershell
$LASTEXITCODE
```

`0` ka matlab command ne success report ki. Koi doosra native executable chalane se pehle check karein, kyun ke woh is value ko badal sakta hai.

Desktop par File Explorer ya PowerShell mein destination dekhein:

```powershell
Get-ChildItem C:\Users\filetransfer\Transfers\vmware
```

Zaroori ISO ke liye source aur destination ke SHA256 hashes compare karein. Dono computers par ek hi file chunein:

**Laptop:**

```powershell
Get-FileHash "C:\Linux\vmware\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso" -Algorithm SHA256
```

**Desktop:**

```powershell
Get-FileHash "C:\Users\filetransfer\Transfers\vmware\VMware-VMvisor-Installer-8.0U3e-24677879.x86_64.iso" -Algorithm SHA256
```

Agar ISO subfolder ke andar ho to dono paths us ke mutabiq badlein. Hashes match hone se tasdeeq hoti hai ke dono copies ka content ek jaisa hai. Download ki authenticity check karne ke liye software publisher ke official checksum se alag compare karein.

## 13. Troubleshooting

| Masla | Matlab / agla check |
|---|---|
| `ssh` ya `scp` recognized nahi | Laptop par OpenSSH Client check/install karein |
| `TcpTestSucceeded : False` | Current IP, desktop ka awake hona, `sshd`, firewall rule aur network isolation check karein |
| Ping fail magar TCP kamyab | ICMP filtered ho sakta hai; SSH ke saath aage barhein |
| Host authenticity prompt | Accept karne se pehle desktop ka host fingerprint verify karein |
| Password prompt par `Permission denied` | Destination username aur account password check karein; PIN alag hai |
| Password characters nazar nahi aate | Terminal ka normal rawayya hai |
| `No such file or directory` | Source path, current directory aur destination folder check karein |
| File likhne par permission denied | Aisa folder use karein jahan SSH account ko write permission ho |
| Transfer ruk gaya | Connectivity/disk space check karein; dobara chalane par SCP aam tor par us file ko shuru se copy karta hai |
| VMware adapter IP par timeout | Is tareeqay mein desktop ka LAN IP istemal karein |
| Pehle chalne wala IP jawab nahi deta | `ipconfig` dobara dekhein; DHCP ne doosra address diya ho sakta hai |

Desktop par Administrator PowerShell mein kaam ke checks:

```powershell
Get-Service sshd
Get-NetTCPConnection -State Listen -LocalPort 22
Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP"
```

## 14. Quick reference aur practice jawabat

### Hamare qadam

1. Dono PCs par `ipconfig` check karein.
2. Connected Wi-Fi/Ethernet addresses, masks aur gateways pehchanein.
3. Desktop ka LAN IP `10.0.0.213` chunein.
4. Laptop se TCP port 22 test karein.
5. Desktop par OpenSSH Server install/start karein aur firewall rule enable karein.
6. TCP test kamyab hone tak dobara check karein.
7. SSH se connect karein aur host identity verify karein.
8. `filetransfer` account se authentication ka masla hal karein.
9. Write permission wala destination folder banayein.
10. Laptop se SCP chalayein.
11. Completion check karein aur zaroori files verify karein.

### Practice sawalat aur jawabat

| Sawal | Jawab |
|---|---|
| Hum ne desktop ka kaun sa IP istemal kiya? | `10.0.0.213`, jo us ka Ethernet LAN address hai |
| Subnet mask kyun check kiya? | Dekhne ke liye ke dono IPv4 addresses ek hi subnet mein hain ya nahi |
| Kya dono PCs ka Wi-Fi par hona zaroori hai? | Nahi; Wi-Fi aur Ethernet home LAN par communicate kar sakte hain |
| Kya local SCP ko internet chahiye? | Nahi, jab zaroori software install ho chuka ho |
| Kya local SCP ko router port forwarding chahiye? | Nahi |
| SSH connections kaun si service receive karti hai? | Desktop par `sshd` |
| SSH ka default port kya hai? | TCP 22 |
| Kya TCP success se password sahi hona sabit hota hai? | Nahi; connection aur authentication alag checks hain |
| Ping fail hone par hum kyun nahi ruke? | Ping aur SSH ke protocols aur firewall rules mukhtalif hain |
| `-r` kya karta hai? | Directory aur us ke contents recursively copy karta hai |
| `.\vmware` ka matlab kya hai? | Current local directory ke andar vmware folder |
| Pull command ke aakhir ka `.` kya hai? | Current local directory mein save karna |
| Kya laptop ka password dena hai? | Nahi; destination desktop account ke credentials dein |
| Kya Windows Hello PIN SSH password ke tor par chalta hai? | Nahi |
| Kya copy karne se source delete hota hai? | Nahi |
| Kya destination par same naam ki files overwrite ho sakti hain? | Haan |

### Official references

- [Microsoft: Windows ke liye OpenSSH install aur start karna](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse)
- [Microsoft: OpenSSH aur Windows Firewall troubleshooting](https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/troubleshoot-openssh-windows-firewall-port22)
- [Microsoft: Test-NetConnection](https://learn.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection)
- [OpenSSH: scp manual](https://man.openbsd.org/scp)

Yeh notes hamara asal kamyab setup record karte hain aur mustaqbil ki practice ke liye verification ke qadam dete hain. Sirf in notes ko parhne se kisi computer ki configuration nahi badalti.
