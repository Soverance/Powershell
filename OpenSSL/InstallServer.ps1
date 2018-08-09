# 

# Get the latest version of OpenSSL binaries for Windows:  https://github.com/PowerShell/Win32-OpenSSH/releases
# Extract the package and put it somewhere more efficient, such as C:\Program Files\OpenSSH\
# Open an elevated Powershell window and run the following commands:

cd "C:\Program Files\OpenSSH"

# install the SSHD and ssh-agent services
./install-sshd.ps1

# generate the server's RSA keys
./ssh-keygen.exe

# when the ssh-keygen application runs, you'll be prompted with a line such as:
# "Enter file in which to save the key (C:\Users\%UserName%/.ssh/id_rsa):
# At the prompt, enter the working directory where you would like to save the key, as well as the key's file name.
# In this case, I usually specify "C:\Program Files\OpenSSH\keys" as the working directory, 
# so the full value might be entered as "C:\Program Files\OpenSSH\keys\soverance"

# when this command completes, two files will be created in the "keys" directory:
# soverance
# soverance.pub

# open a firewall rule to allow port 22
# you will also need to open this port within the Azure portal, if necessary
New-NetFirewallRule -Protocol TCP -LocalPort 22 -Direction Inbound -Action Allow -DisplayName SSH

# set the ssh services to automatic startup type
Set-Service -Name "sshd" -StartupType Automatic
Set-Service -Name "ssh-agent" -StartupType Automatic

# start the ssh services
Start-Service -Name "sshd"
Start-Service -name "ssh-agent"

# Once the services have been started for the first time, the .ssh working directory will be created within
# C:\ProgramData\.ssh\

# you must manually edit the "sshd_config" file to modify the user's starting home directory
# use Explorer to navigate to C:\ProgramData\ssh\sshd_config and open the file in a text editor
# near the bottom, a call will be made "Subsystem   sftp   sftp-server.exe"
# You must add a -d argument to the sftp-server.exe call to specify your custom home directory
# i.e., "Subsystem   sftp   sftp-server.exe -d C:\inetpub\wwwroot"

# at this point, you'll just use regular Windows user accounts and NTFS permissions to secure the file directories
# since SSH is a linux protocol and Microsoft therefore doesn't support CHROOT, we don't have many other options for this without installing additional software

# restart the ssh services since changes were made to the sshd_config file
Restart-Service -Name "sshd"
Restart-Service -name "ssh-agent"