# netmonitor

___
#### Scripts -- monitor network connectivity, outages, and IP address changes

- run.sh -- launcher script for init service
- ip/ipmon.py -- tracks IP changes
  - returns failure if can't get current public IP
  - returns the exit code of ip/ipaction.py based on current IP
- ip/ipaction.py -- performs an action based on an IP
  - customizable implementation
  - example usage provided to send an email when the IP address changes
  - return value of `receivedip(ip)` indicates success to ipmon
- net/netmon.sh -- monitor script, intended to be ran as a daemon
  - calls net/wait4net.sh on outage, tracks time of outages
  - calls ip/ipmon.py when outage ends
- net/wait4net.sh -- attempts `curl` until the command succeeds
  - useful as a standalone script, when waiting for connectivity to return
- util/secs2text.sh -- converts numeric seconds to human-readable text
- util/text2secs.sh -- converts human-readable text to numeric seconds

___
### Usage as an IP monitor

`ip/ipmon.py` can be set to run periodically, e.g., as a cron job.

If it fails to get the current IP,
or the action in ip/ipaction.py fails,
then that run of the script will fail.

Setting the run to be periodic (though not continuous)
should be enough to, e.g., notify or track IP address changes.

___
### Usage as complete network and IP monitor

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

**NOTE:** enable/add commands are to automatically start in the future

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
