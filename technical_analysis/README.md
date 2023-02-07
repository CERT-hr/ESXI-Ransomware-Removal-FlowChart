# Notes 

- This is the first (quick) version of the analysis.  
- This refers to 2 original files attached in this folder
- Please contact us via MM or at fomazic@cert.hr for all the changes you'd like to make or code you'd like to ask about.
- Encrypt.code's .code extension isn't its real extension

# Summary 

- Main .sh file runs the main operation that when ready runs encryption. (Main .sh file runs a compiled version of encrypt.code)
- The main .sh file in question also seems to use a lot of files in /tmp - so we're assuming that's where the attacker unpacked ransom note, main .sh file, 
encrypt.code file, public key (to be used in encryption) and more.
- Encrypt.code is compiled to an executable file and its used to encrypt the files.

# Main .sh file activities

- Specifies a variable CLEAN_DIR which is /tmp
- Uses ulimit (requires high privs) to change the limit on resources for certain users or set restrictions
- replaces config contents, for every config it finds using "esxcli vm process list"
- Kills VMX  
- Starts with encrypt operation:
	1) chmod encrypt binary
	2) for every volume in esxcli's storage filesystem it looks up /vmfs/volumes/{volumeHere} 
	catches extensions like:
		- vmdk, vmx, vmxf, vmsd, vmsn, vswp, vmss, nvram, vmem, ...
	3) If size of a file is not 0, then define steps for encryption. 
		- It encrypts files smaller than 128mb easily, but for files over 128mb it encrypts it in chunks
	4) Starts encryption with defined steps - runs encrypt binary.
		- For this it uses public.pem in the same directory where the encrypt binary is (CLEAN_DIR)
- Puts up index.html ransom note 
- Puts up SSH message of the day ransom note
- Deletes all the logs it can find ending with .log (searches /) 
- Counts the number of processes with "encrypt" in them and waits until they are all done
- If the file /sbin/hostd-probe.bak exists it removes hostd-probe and moves hostd-probe.bak to /sbin/hostd-probe
		- Then it updates the timestamp of the busybox file : /usr/lib/vmware/busybox/bin/busybox  with timestamps of /sbin/hostd-probe
- Lists out vmware "7." version and counts lines of output
		- If line number isnt zero it :
			- Chmods for writing this file : /var/spool/cron/crontabs/root 
			- ... 
			* TODO
		- If its zero 
			* TODO 
- Removes /store/packages/vmtools.py, moves content of endpoints.conf to endpoints.conf.1 and moves content of that same file back into endpoints.conf ? what?
- Echoes nothing into /etc/rc.local.d/local.sh 
- Updates the timestamp of the config.xml to endpoints.conf's timestamp
			- Then it overwrites config.xml's timestamp with /bin/hostd-probe.sh's, then with /etc/rc.local.d's 
- It cleans the encrypt file, nohup.out (compiled binary), index.html, motd, and public.pem as well as "archieve.zip"
		- to not leave traces
- Removes /bin/auto-backup.sh and it removes itself.
- Starts SSH

# Encrypt.code activities

- Prints out help if the input is wrong, checks inputs to be valid always
- Else statements just return exit codes with different numbers (and specify where the error occured)
- Creates RSA object
- Encrypts file

Additional Notes:
- get_pk_data gets public key data
- This looks like it came from Ghidra....
- It does most of the operations with param_2, it just checks if statements for param_1
	- and it checks it odd way. I assume its length considering the help print statement also has a similar IF, if so - all the if statements below are ran because len(encrypt) is over 5 or whatever the highest number check there is
- TODO 







