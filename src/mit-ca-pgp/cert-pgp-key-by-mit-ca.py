import urllib, urllib2, cookielib
import base64
import subprocess
import atexit
from subprocess import PIPE

print "if you're paranoid about hard drive forensics, run this program in a ramdisk"
print "Please enter the following:\nPGP key ID\\n\nUsername\\n\nPassword\\n\nMIT ID\\n"
keyid, username, password, mitid = raw_input(), raw_input(), raw_input(), raw_input()

subprocess.call(['mkdir', 'tmpgpg'])
subprocess.call(['cp ~/.gnupg/pubring.gpg tmpgpg'], shell=True)
subprocess.call(['cp ~/.gnupg/secring.gpg tmpgpg'], shell=True)
subprocess.call(['gpg', '--homedir=tmpgpg', '--passwd', keyid])

@atexit.register
def goodbye():
    subprocess.call(['shred', '-u', 'tmpgpg/pubring.gpg'])
    subprocess.call(['shred', '-u', 'tmpgpg/secring.gpg'])
    subprocess.call(['rm', '-rf', 'tmpgpg'])


cj = cookielib.CookieJar()
opener = urllib2.build_opener(urllib2.HTTPCookieProcessor(cj))
opener.addheaders = [('User-agent', 'Mozilla/5.0 (X11; Linux x86_64; rv:23.0) Gecko/20100101 Firefox/23.0')]

p_login = ('data=1&login=' + urllib.quote_plus(username) +
         '&password=' + urllib.quote_plus(password) +
         '&mitid=' + urllib.quote_plus(mitid) + '&Submit=Next+%3E%3E')

opener.open('https://ca.mit.edu/').read()
text = opener.open('https://ca.mit.edu/ca/login', p_login).read()

def after(t,x):
    return t[t.find(x)+len(x):]

life = after(text, 'The default life of ').split()[0]
challenge = after(text, 'challenge="').split('"')[0]
print 'Logged in; life:', life, 'challenge:', challenge

print 'We just created a copy of your gpg keyring, which we are going to erase later'
print 'In order to create a certificate request, we need an unportected gpg secret key'
print '\n\n*** Please set no password, make it empty**\n\n'
gpgkey = subprocess.Popen(['gpg', '--homedir=tmpgpg', '--export-secret-key', keyid], stdout=PIPE)
rsakey = subprocess.Popen(["openpgp2ssh", keyid], stdin=gpgkey.stdout, stdout=PIPE)
spkac = subprocess.Popen(["openssl", "spkac", "-key", "/proc/self/fd/0", "-challenge", challenge], stdin=rsakey.stdout, stdout=PIPE).communicate()[0].strip()[6:]

p_spkac = ('data=1&userkey=' + urllib.quote_plus(spkac) +
           '&life=' + life + '&Submit=Next+%3E%3E')
opener.open('https://ca.mit.edu/ca/handlemoz', p_spkac).read()
der_cert = opener.open('https://ca.mit.edu/ca/mozcert/2').read()

print ("""
-----BEGIN CERTIFICATE-----
%s
-----END CERTIFICATE-----
""" % base64.encodestring(der_cert)).rstrip()
