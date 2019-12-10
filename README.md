*** Work in progress ***

# Introduction rrd4j2influx
Migrate openHAB persistance data from rrd4j service to influx db (Openhab 2.2)

This Powershell is inspired by a bash script from  https://github.com/CWempe/rest2influxdb . That script is not compatible with openHAB 2.1 or higher. 
This Powershell script has only been tested with openHab 2.2. openHAB does not need to be running on Windows. As long as the correct server adress are configured it will work.

The script will read data from openHAB via the REST interface and then import them to influxdb by using the line protocol.

# Usage
open the script in Powershell ISE 
rrd4j2influx($itemname)

# To Do
- decide : Signing script or explain how to run unsigned PoSh scripts
- check if the dates to checked can be smaller to get as much data as possible from the rrd4j service
- decide : inlcude reading groups from REST and running the function to import those ?
- decide : store files in a config, like in http://www.sharepointpals.com/post/How-to-Read-the-values-from-Config-File-PowerShell

# (un)known Issues
- RRD compresses data, so the further you go into the past the bigger gaps you get between two data points.
see: https://github.com/openhab/openhab1-addons/wiki/rrd4j-persistence
- I am not sure if the defined timestamps are correct to read as much data as possible
