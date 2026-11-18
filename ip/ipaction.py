#! /usr/bin/env python3

import os
from subprocess import DEVNULL, PIPE, Popen, TimeoutExpired

# file to track the last known IP
ipfile = os.path.join(os.path.dirname(__file__), 'lastip')

# whether we use mutt to email the new IP
usemutt = True
# if we do, set the email, otherwise the email is blank
sendto = 'recipient@example.com' if usemutt else ''
# email subject, used when usemutt and sendto
subject = 'New IP'

''' run
  wrapper for Popen
  arguments for Popen: cmd, stdin, stdout, stderr
  arguments for Popen.communicate: input, timeout

  returns tuple: (returncode, (stdout, stdin))

  stdout/stderr may be None
  exceptions set returncode to 1
  when returncode < 0 it is a signal
    signal name = signal.Signals(-returncode).name
'''
def run(cmd, input, timeout, stdin, stdout, stderr):
  proc = Popen(cmd, stdin=stdin, stdout=stdout, stderr=stderr)
  try:
    output = proc.communicate(input=input, timeout=timeout)
  except Exception as e:
    proc.kill()
    if isinstance(e, TimeoutExpired):
      return 1, (None, 'Command timed out')
    else:
      return 1, (None, str(e))
  return proc.returncode, output

''' mailip
  called when usemutt True above (we have an email to send to)
  returns True if we finish sending the email, False if there are any failures

  this example calls a few programs, piping output, to generate more text

  this is a functional example if mutt is configured and the programs exist
'''
def mailip(ip):
  # use fortune, cowsay, and mutt
  fortune = ['fortune', '-ac']
  cowsay = ['cowsay', '-W', '42', '-e', 'oO']
  mutt = ['mutt', '-s', subject, '--', sendto]
  # use fortune for some text
  kwargs = {'cmd': fortune,
            'input': None,
            'timeout': 1,
            'stdin': DEVNULL,
            'stdout': PIPE,
            'stderr': DEVNULL,
            }
  fortune = run(**kwargs)
  if fortune[0] != 0:
    return False
  # pipe fortune to cowsay
  kwargs['cmd'] = cowsay
  kwargs['input'] = fortune[1][0]
  kwargs['stdin'] = PIPE
  cowsay = run(**kwargs)
  if cowsay[0] != 0:
    return False
  cowsay = '\n'.join(['', cowsay[1][0].decode('utf-8'), '', ip, ''])
  kwargs['cmd'] = mutt
  kwargs['input'] = cowsay.encode()
  kwargs['timeout'] = 30
  kwargs['stdout'] = DEVNULL
  mutt = run(**kwargs)
  return mutt[0] == 0

# return True if we have the old ip in a file and it is the same
def ipnotchanged(ip):
  if os.path.isfile(ipfile):
    with open(ipfile, 'r') as infile:
      oldip = infile.read().strip()
    if ip == oldip:
      return True
  return False

# called from ipmon.py, return True if our action succeeds else False
def receivedip(ip):
  # the IP is the same as it was before
  if ipnotchanged(ip):
    return True
  # we have an email address to send it to
  if sendto:
    # if we fail to send the email, we failed to complete the update
    if not mailip(ip):
      return False
  else:
    # if we didn't have an email, print it to the screen and call it a success
    print(f'updated ip: {ip}')
  # record the current ip and return success
  with open(ipfile, 'w') as outfile:
    outfile.write(ip + '\n')
  return True
