from paramiko import SSHClient,AutoAddPolicy
import os,sys
from pathlib import Path
import datetime
import time
import pysftp

cisco = {'sw1':'1.1.2.1','sw2':'1.1.2.2'}

login = 'test'
passwd = 'test'

def get_key(val):
	for key, value in cisco.items():
		if val == value:
			return key

if not os.path.exists(str(Path.home())+'/Backup'):
	os.mkdir(str(Path.home())+'/Backup',0o777)

today = str(datetime.date.today())
path_backup = str(Path.home())+'/Backup'+'/'+today
if not os.path.exists(path_backup):
	os.mkdir(path_backup,0o777)	

	
ssh = SSHClient()
ssh.set_missing_host_key_policy(AutoAddPolicy())
nf = open(path_backup+"/errors.txt", "w")
for i in cisco.values():
	try:
		ssh.connect(hostname=i,username=login,password=passwd, timeout=10)
		shell = ssh.invoke_shell()
		time.sleep(1)
		shell.send('term len 0\n')
		time.sleep(1)
		shell.send('show run\n')
		time.sleep(10)
		output = shell.recv(10000).decode(encoding='utf-8')
		filename = os.path.join(path_backup+'/',i+'.txt')
		f = open(filename,'a')
		f.write(str(output))
		f.close()
		ssh.close()
	except:
		nf.write(str(get_key(i))+'\n')		
nf.close()
