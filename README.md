# netmonitor
### These scripts monitor network connectivity, outages, and IP address changes

___
### Usage

___
#### Scripts

- run.sh -- launcher script for init service
- ip/ipmon.py -- tracks IP changes
  - returns failure if can't get current public IP
  - returns the exit code of ip/ipaction.py based on current IP
- ip/ipaction.py -- performs an action based on an IP
  - customizable implementation
  - can store previous IP, do some action based on whether it changed
  - return value of `receivedip(ip)` indicates success of ipmon
- net/netmon.sh -- monitor script, intended to be ran as a daemon
  - calls net/wait4net.sh on outage, tracks time of outages
  - calls ip/ipmon.py when outage ends
- net/wait4net.sh -- attempts `curl` until the command succeeds
- util/secs2text.sh -- converts numeric seconds to human-readable text
- util/text2secs.sh -- converts human-readable text to numeric seconds

`net/wait4net.sh` can be useful when waiting for connectivity to return
___
#### Installation - openrc/systemd

2 service files are provided, `netmonitor.in` and `netmonitor.service.in`,
for openrc and systemd, respectively.

The script is intended to run as a normal user, i.e., your user.

Clone this repository to its installed location, for example:
```bash
git clone https://github.com/chaseleif/netmonitor.git ~/.netmonitor
cd ~/.netmonitor
```

The script `setup.sh` will replace needed variables in `netmonitor*.in` files:
```bash
./setup.sh
```

For systemd:
```bash
sudo mv netmonitor.service /etc/systemd/system/netmonitor.service
sudo systemctl daemon-reload
sudo systemctl start netmonitor
sudo systemctl enable netmonitor
sudo systemctl status netmonitor
```
For openrc:
```bash
sudo mv netmonitor /etc/init.d/netmonitor
sudo rc-service netmonitor start
sudo rc-update add netmonitor
sudo rc-service netmonitor status
```

**NOTE:** enable is to automatically start in the future

The init script will run `run.sh` from its directory.

___
#### Logs

Outages are recorded in `outages.log` in the same directory as `run.sh`.

Using `net/netmon.sh`, `run.sh` records in `outages.log`
- when the script starts and is killed
- when an outage starts and when it ends
- the duration of the current outage and the cumulative outage duration

Total outage duration accumulates through the life of `outages.log`.

On restart, the last line beginning with 'Total outages: '
is used to restore the running total.
