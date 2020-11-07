# netgear-m1

An utility for querying and controlling a [Netgear M1 router](https://www.netgear.com/home/products/mobile-broadband/mobilerouters/MR1100.aspx).

I am mostly happy with my Netgear M1 mobile router, but the cellular data connection tends to slow down over time but recovers if I reboot the router. I made this utility for an easy way for periodically rebooting the router.

This utility is based on a Perl script I found on an [Netgear community discussion thread](https://community.netgear.com/t5/Mobile-Routers-Hotspots-Modems/MR1100-fails-to-reestablish-the-connection-after-the-hang-up/m-p/1918046). Use at your own risk. I have no affiliation with Netgear.

## Requirements

The utility only requires very common UNIX tools:

- [bash](https://www.gnu.org/software/bash/)
- [curl](https://curl.haxx.se/) and
- [mktemp](https://www.gnu.org/software/autogen/mktemp.html)

## Commands

The commands control the router.

By default the utility connects router at IP address 192.168.1.1.
Another IP address can be provided environment variable `NETGEAR_M1_IP`.

### status

This command returns basic information about the status of the router. Status information can be queried without providing admin password.

```
$ ./netgear-m1.sh status
             Device name: Nighthawk M1
    Battery charge level: 84
              IP address: 192.168.1.99
      Current radio band: LTE B20
        Data transferred: 142027842799
Router connection status: Connected
```

The `--json` flag can be used to store all status information provided by the router.

```
$ ./netgear-m1.sh status --json > model.json
```

### reboot

This command reboots the router

```
$ ./netgear-m1.sh reboot
Password:
Logged in to Nighthawk M1
Rebooting...
```

### disconnect

This command disconnects the cellular data connection of the router.

```
$ ./netgear-m1.sh disconnect
Password:
Logged in to Nighthawk M1
Disconnected cellular data
```

![mobile data connection disconnected](https://raw.githubusercontent.com/mtreinik/netgear-m1/main/docs/disconnected.png)

### connect

This command connects the cellular data connection of the router.

```
$ ./netgear-m1.sh connect
Password:
Logged in to Nighthawk M1
Connected cellular data
```

![mobile data connection connected](https://raw.githubusercontent.com/mtreinik/netgear-m1/main/docs/connected.png)

### reconnect

This command disconnects and connects the cellular data connection of the router.

```
$ ./netgear-m1.sh reconnect
Password:
Logged in to Nighthawk M1
Disconnected cellular data
Connected cellular data
```
