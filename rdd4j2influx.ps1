$itemname=$null
rrd4j2influx($itemname)


function rrd4j2influx($itemname){

if($itemname -eq $null){break}

# openHAB server
$openhabserver="openHab-server"
$openhabport="8080"
$serviceid="rrd4j"

# InfluxDB server
$influxserver="influxdb-server"
$influxport="8086"
$influxdatbase="openhab_db"
$influxuser="openhab"
$influxpw="StrongPassword"
$importsize=500
$sleeptime=2


# convert historical times to unix timestamps,
$tenyearsago=get-date -format s -Date (get-date).Addyears(-10)
$oneyearago=get-date -format s -Date (get-date).Addmonths(-12).AddDays(-28)
$onemonthago=get-date -format s -Date (get-date).Adddays(-29)
$oneweekago=get-date -format s -Date (get-date).AddDays(-6).AddHours(-23).AddMinutes(-29)
$onedayago=get-date -format s -Date (get-date).AddHours(-23).AddMinutes(-29)
$eighthoursago=get-date -format s -Date (get-date).AddHours(-8).AddMinutes(-59)

# print timestamps
echo ""
echo "### timestamps"
echo "item: $itemname"
echo "10y:  $tenyearsago"
echo "1y:   $oneyearago"
echo "1m:   $onemonthago"
echo "1w:   $oneweekago"
echo "1d:   $onedayago"
echo "8h:   $eighthoursago"

#set baseurl
$baseurl="http://$openhabserver`:$openhabport/rest/persistence/items/$itemname`?serviceId=$serviceid"
$webclient = New-Object System.Net.WebClient

#download data and convert to objects
Write-Host "Loading $Itemname from OH"
$persist10y = $webClient.DownloadString("$baseurl&starttime=$tenyearsago&endtime=$oneyearago") | ConvertFrom-Json
$persist1y = $webClient.DownloadString("$baseurl&starttime=$oneyearago&endtime=$onemonthago") | ConvertFrom-Json
$persist1m = $webClient.DownloadString("$baseurl&starttime=$onemonthago&endtime=$oneweekago") | ConvertFrom-Json
$persist1w = $webClient.DownloadString("$baseurl&starttime=$oneweekago&endtime=$onedayago") | ConvertFrom-Json
$persist1d = $webClient.DownloadString("$baseurl&starttime=$onedayago&endtime=$eighthoursago") | ConvertFrom-Json
$persist8h = $webClient.DownloadString("$baseurl&starttime=$eighthoursago") | ConvertFrom-Json

#break is there is no data
if($persist10y.name -ne $itemname){break}
#$persist10y.datapoints
#$persist1y.datapoints
#$persist1m.datapoints
#$persist1w.datapoints
#$persist1d.datapoints
#$persist8h.datapoints

#combine results in one big list
Write-host "Combining"
$result = @()
foreach ($data in $persist10y.data){
    $obj = New-Object System.Object 
	$obj | Add-Member -membertype NoteProperty -Name time -Value $data.time
	$obj | Add-Member -membertype NoteProperty -Name state -Value $data.state
    $result += $obj 
}
foreach ($data in $persist1y.data){
    $obj = New-Object System.Object 
	$obj | Add-Member -membertype NoteProperty -Name time -Value $data.time
	$obj | Add-Member -membertype NoteProperty -Name state -Value $data.state
    $result += $obj 
}
foreach ($data in $persist1m.data){
    $obj = New-Object System.Object 
	$obj | Add-Member -membertype NoteProperty -Name time -Value $data.time
	$obj | Add-Member -membertype NoteProperty -Name state -Value $data.state
    $result += $obj 
}
foreach ($data in $persist1w.data){
    $obj = New-Object System.Object 
	$obj | Add-Member -membertype NoteProperty -Name time -Value $data.time
	$obj | Add-Member -membertype NoteProperty -Name state -Value $data.state
    $result += $obj 
}
foreach ($data in $persist1d.data){
    $obj = New-Object System.Object 
	$obj | Add-Member -membertype NoteProperty -Name time -Value $data.time
	$obj | Add-Member -membertype NoteProperty -Name state -Value $data.state
    $result += $obj 
}
foreach ($data in $persist8h.data){
    $obj = New-Object System.Object 
	$obj | Add-Member -membertype NoteProperty -Name time -Value $data.time
	$obj | Add-Member -membertype NoteProperty -Name state -Value $data.state
    $result += $obj 
}

Write-host "Result datapoints : " $result.count


#set influx url and authorization
$authheader = "Basic " + ([Convert]::ToBase64String([System.Text.encoding]::ASCII.GetBytes("${$influxuser}:${influxpw}")))
$uri="http://${influxserver}:${influxport}/write?db=${influxdatbase}&precision=ms"

#prep import
$importbatch = "" 
$line = 0

#do import per importsize
foreach($measurement in $result){
    #convert switch and contact sensors, even though rrd4j should only store numbers the REST returns ON/OFF or OPEN/CLOSED
    if($measurement.state -eq "ON"){$measurement.state=1}
    if($measurement.state -eq "OFF"){$measurement.state=0}
    if($measurement.state -eq "OPEN"){$measurement.state=1}
    if($measurement.state -eq "CLOSED"){$measurement.state=0}

    #add a new line to importbatch
    $importbatch += $itemname + " value=" + $measurement.state + " " + $measurement.time + "`n"
    $line++

    #debug: the line that is added to the importbatch
    #Write-host $line" => "$itemname" value=" $measurement.state " " $measurement.time

    if($line -eq $importsize){
        Write-host "Importing =>" 
        #debug:
        #Write-host $importbatch

        #curl -i -XPOST -u $influxuser:$influxpw "http://$influxserver:$influxport/write?db=$influxdatbase" --data-binary @${itemname}_${linestart}.txt
        Invoke-RestMethod -Method Post -Headers @{Authorization=$authheader}  -Uri $uri -Body $importbatch
        
        #sleep to let influx catch up
        Write-host "Sleeping...."
        sleep $sleeptime
        
        #prep for next batch
        $importbatch = ""
        $line = 0
    }
}
#import the last set of import batch
Invoke-RestMethod -Method Post -Headers @{Authorization=$authheader}  -Uri $uri -Body $importbatch 

}
