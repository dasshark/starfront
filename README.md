# Starfront Automation
After a night of imaging, I need a reliable way to gather the data and push it to my local storage.

## Requirements
- Powershell 7
- WinSCP
- FTP Destination
- NINA Advanced API
- Discord webook destination
- GIT
- github token
- github.token file

## Personal Setup
UGREEN 4 bay NAS with 4x16GB disks (homenas)
Tailscale for ZeroTrust VPN access

## Activities 
1. Test that FTP server is available, exit if not
2. Send NINA logs
3. Send NINA sequence template files
4. Send NINA sequence target files
5. Send NINA sequence files, keep most recent, delete the rest
6. Test NINA sequencer status
   - exit if still running
   - continue if completed
   - continue if API not running, indicating system reboot probable
7. Transfer images
8. Move transferred images to "transferred" folder
