<#TEMPLATE
function  {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName
    )
    BEGIN{}
    PROCESS{
        foreach ($Computer in $ComputerName){
            if (Test-CompConnection $Computer){
              #ENTER IN THE STUFF YOU WANT TO DO/COLLECT
            $props=@{}
               $obj=New-Object -TypeName PSObject -Property $props 
               Write-Output $obj
            }
        }
    }
    END{}
}
#>

function Test-CompConnection($computer){
<#
.SYNOPSIS
Test computer with a ping and WMI call to make sure it is accessible to run cmdlets against.

.DESCRIPTION
Test computer with a ping and WMI call to make sure it is accessible to run cmdlets against.
#>
    $works=$true
    if (Test-Connection $computer -Count 1 -Quiet){
        try{
            Get-WmiObject -Class win32_bios -ComputerName $computer -ErrorAction Stop | Out-Null
        }catch{
            $works=$false
            Write-Host "Was not able to connect to WMI Service on $computer. Check firewall settings"
        }

    }else{
        Write-Host "Was not able to connect to $computer. Check the computer is on."
        $works=$false
    }
    return $works
}


function Get-DCSDHotFixInfo {
<#
.SYNOPSIS
Get Computer HotFix info on local or remote computer(s)

.DESCRIPTION
Get Computer HotFix information.

.PARAMETER ComputerName
Input computer name or names to get information from

.EXAMPLE
Get-DCSDHotFixInfo -ComputerName TESTCOMP01 -HotFixID *
Gets a list of all HotFixes installed on TESTCOMPUTER01

.EXAMPLE
Get-DCSDHotFixInfo -ComputerName TESTCOMPUTER01 -HotFixID KB401990
Checks TESTCOMP01 to see if HotFix KB401990 is installed

.EXAMPLE
Get-DCSDHotFixInfo -ComputerName ((Get-ADComputer -Filter *).Name) -HotFixID *
Gets a list of all HotFixes installed on ev

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string[]] $HotFixID = "*"
    )
    BEGIN{}
    PROCESS{
        foreach ($Computer in $ComputerName){
            if (Test-CompConnection $Computer){
                Get-WmiObject -ComputerName $Computer Win32_QuickFixEngineering |
                Where-Object HotFixiD -like $HotFixID|
                Select-Object PSComputerName, HotFixID,InstalledOn
            }

        }
    }
    END{}
}




function Get-DCSDComputerInfo {
<#
.SYNOPSIS
Get Computer info on local or remote computer(s)

.DESCRIPTION
Get Computer Manufacturer, Model, Serial, Asset Tag, Memory, OS Versions, Imaged Date and User Logged on Info.

.PARAMETER ComputerName
Input computer name or names to get information from


#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName
    )
    BEGIN{}
    PROCESS{
        foreach ($Computer in $ComputerName){
            if (Test-CompConnection $Computer){
               $cs = Get-WmiObject -Class win32_ComputerSystem -ComputerName $Computer
               $sysenc = Get-WmiObject -Class win32_SystemEnclosure -ComputerName $Computer
               $memory = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem  -computer $Computer).TotalPhysicalMemory/1GB)
               $OS = Get-WmiObject -ComputerName $Computer -Class Win32_OperatingSystem
                    $props=[ordered]@{
                            'Computer Manufacturer' = $cs.Manufacturer;
                            'Computer Model' = $cs.Model;
                            'Computer Name' = $cs.Name;
                            'Computer Serial' = $sysenc.SerialNumber;
                            'Computer Asset' = $sysenc.SMBIOSAssetTag;
                            'Computer Memory(GB)' = $memory;
                            'Logged In'= $cs.UserName;
                            'OS Version' = $OS.Caption;
                            'Imaged on' = $OS.ConvertToDateTime($OS.InstallDate) -f "MM/dd/yyyy" 
                     }
                       $obj=New-Object -TypeName PSObject -Property $props
                       Write-Output $obj
            }
        }
    }
    END{}

}

function Get-DCSDComputerHDInfo {
<#
.SYNOPSIS
Gets hard drive information from computer(s)

.DESCRIPTION
Gets hard drive information from computers including Drive Letter, Total Size and Free Space rounded to the closest GB.

.PARAMETER ComputerName
Input computer name or names to get information from
.PARAMETER DriveLetter
Defaults to C: drive info but you can specify another drive with this parameter.
.EXAMPLE
Get-DCSDComputerHDINfo -ComputerName TESTCOMP01
Returns total size, free space and volume name from the C: drive on TESTCOMP01 computer
Get-DCSDComputerHDINfo -ComputerName TESTCOMP01 -DriveLetter E:
Returns total size, free space and volume name from the E: drive on TESTCOMP01 computer

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string[]] $DriveLetter = "C:"
    )
    BEGIN{}
    PROCESS{
        foreach ($Computer in $ComputerName){
            if (Test-CompConnection $Computer){
              $Drive = Get-WmiObject -ComputerName $ComputerName Win32_LogicalDisk |Where-Object DeviceID -EQ "$DriveLetter"
              $TotalSize = [math]::Round(($Drive).Size/1GB)
              $FreeSpace = [math]::Round(($Drive).FreeSpace/1GB)

                $props=[ordered]@{
                    'Drive Letter' = $Drive.DeviceID;
                    'Drive Name' = $Drive.VolumeName;
                    'Total Size(GB)' = $TotalSize;
                    'Free Space(GB)' = $FreeSpace;
                }
               $obj=New-Object -TypeName PSObject -Property $props 
               Write-Output $obj
            }
        }
    }
    END{}
}



function Get-DCSDAppInfo {
<#
.SYNOPSIS
Get Application info on local or remote computer(s)

.DESCRIPTION
Get Applicaiton information via WMI from a local or remote computer(s).

.PARAMETER ComputerName
Input computer name or names to get AppInfo from

.PARAMETER ApplicationName
Enter name of application you are looking for *Adobe*

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,
        [string]$ApplicationName = "*"

        
    )
    BEGIN{}
    PROCESS{
        foreach ($Computer in $ComputerName){
                if (Test-CompConnection $Computer){
                    Get-WmiObject -Class win32_product -ComputerName $Computer |
                    Where-Object Name -Like $ApplicationName |
                    Select-Object PSComputerName,Name,Version,InstallDate
                }
        }

    }
    END{}
}



function Start-Monitor {
<#

.SYNOPSIS
Monitor computer(s) connected to a network.

.DESCRIPTION
Monitor computer(s) connected to a network with switches to email with the computer(s) go offline and when they come back online.

.PARAMETER ComputerName
Input computer name or names to monitor

.PARAMETER NotifyOnServerDown
Switch to Enable Email Notifications on First Down

.PARAMETER NotifyOnServerBackOnline
Switch to Enable Email Notifications on Server Online

.PARAMETER NotifyOnMaxOutageCount
Switch to Enable Email Notifications on MaxOutageCount

.PARAMETER NotifyAll
Switch to Enable all notifications

.PARAMETER EmailTimeOut
Specify the time you want email notifications resent for hosts that are down.
Default is 30 seconds

.PARAMETER SleepTimeOut
Specify the time you want to cycle through your host lists
Default is 60 seconds

.PARAMETER MaxOutageCount
Specify the maximum hosts that can be down before the script is aborted
Default is 100

.PARAMETER ToNotification
Specify the email address of who gets notified
May want to change the default to suite your domain.
.PARAMETER FromNotification
Specify email address where the notifications come from 
May want to change the default to suite your domain.
.PARAMETER SMTPServer
Specify the SMTP Server for sending notification emails
May want to change the default to suite your domain.

.NOTES
I modified the orianal found on think link in help.

.LINK
https://gallery.technet.microsoft.com/scriptcenter/2d537e5c-b5d4-42ca-a23e-2cbce636f58d

#> 
     
      #Requires -Version 2.0            
      [CmdletBinding()]            
      Param             
      (                       
            [Parameter(Position=0,                         
                       ValueFromPipeline=$true,            
                       ValueFromPipelineByPropertyName=$true)]
            [String[]]$ComputerName = $env:COMPUTERNAME,        
            
            # Switch to Enable Email Notifications on First Down
            [Switch]$NotifyOnServerDown,
            
            # Switch to Enable Email Notifications on Server Online
            [Switch]$NotifyOnServerBackOnline,
            
            # Switch to Enable Email Notifications on MaxOutageCount
            [Switch]$NotifyOnMaxOutageCount,
            
            # Switch to Enable all notifications
            [Switch]$NotifyAll,

            # specify the time you want email notifications resent for hosts that are down
            $EmailTimeOut = 30,
            # specify the time you want to cycle through your host lists
            $SleepTimeOut = 60,
            # specify the maximum hosts that can be down before the script is aborted
            $MaxOutageCount = 100,
            
            # specify who gets notified 
            $ToNotification = "$env:username@davenport.k12.ia.us", 
            # specify where the notifications come from 
            $FromNotification = "$env:username@davenport.k12.ia.us", 
            # specify the SMTP server 
            $SMTPServer = "aspmx.l.google.com",
            
            # reset the lists of hosts prior to looping
            $OutageHosts = @()            
      )#End Param
 
 # Use end block, to ensure all computers are read in at once, even by pipeline     
 end {     
      if ($notifyAll)
      {
            $notifyonMaxOutageCount,$notifyonServerBackOnline,$notifyonServerDown =  $True,$True,$True
      }

      Write-Verbose -Message "computername: $computername"
      Write-Verbose -Message "notifyonMaxOutageCount: $notifyonMaxOutageCount"
      Write-Verbose -Message "notifyonServerBackOnline: $notifyonServerBackOnline"
      Write-Verbose -Message "notifyonServerDown: $notifyonServerDown"

      # Allow
      if ( $Input )
      {
            Write-Verbose -Message "Input: $Input"
            $ComputerName = $Input
      }
      
      # start looping here
      Do{
            $available = @()
            $notavailable = @()
            Write-Host (Get-Date)
            
            # Read the File with the Hosts every cycle, this way to can add/remove hosts
            # from the list without touching the script/scheduled task, 
            # also hash/comment (#) out any hosts that are going for maintenance or are down.
            $ComputerName | Where-Object {!($_ -match "#")} | 
            #"test1","test2" | Where-Object {!($_ -match "#")} |
            ForEach-Object {
                  if(Test-Connection -ComputerName $_ -Count 1 -ea silentlycontinue)
                  {
                        # if the Host is available then write it to the screen
                        write-host "Available host ---> "$_ -BackgroundColor Green -ForegroundColor White
                        [String[]]$available += $_
                        
                        # if the Host was out and is now backonline, remove it from the OutageHosts list
                        if ($OutageHosts -ne $Null)
                        {
                              if ($OutageHosts.ContainsKey($_))
                              {
                                    $OutageHosts.Remove($_)
                                    $Now = Get-date
                                    if ($notifyonServerBackOnline)
                                    {
                                          $Body = "$_ is back online at $Now"
                                          Send-MailMessage -Body "$body" -to $tonotification -from $fromnotification `
                                          -Subject "Host $_ is up" -SmtpServer $smtpserver
                                    }
                                    
                              }
                        }  
                  }
                  else
                  {
                        # If the host is unavailable, give a warning to screen
                        write-host "Unavailable host ------------> "$_ -BackgroundColor Magenta -ForegroundColor White
                        if(!(Test-Connection -ComputerName $_ -Count 2 -ea silentlycontinue))
                        {
                              # If the host is still unavailable for 4 full pings, write error and send email
                              write-host "Unavailable host ------------> "$_ -BackgroundColor Magenta -ForegroundColor White
                              [Array]$notavailable += $_
                              
                              if ($OutageHosts -ne $Null)
                              {
                                    if (!$OutageHosts.ContainsKey($_))
                                    {
                                          # First time down add to the list and send email
                                          Write-Host "$_ Is not in the OutageHosts list, first time down"
                                          $OutageHosts.Add($_,(get-date))
                                          $Now = Get-date
                                          if ($notifyonServerDown)
                                          {
                                                $Body = "$_ has not responded for 5 pings at $Now"
                                                Send-MailMessage -Body "$body" -to $tonotification -from $fromnotification `
                                                -Subject "Host $_ is down" -SmtpServer $smtpserver
                                          }
                                    }
                                    else
                                    {
                                          # If the host is in the list do nothing for 1 hour and then remove from the list.
                                          Write-Host "$_ Is in the OutageHosts list"
                                          if (((Get-Date) - $OutageHosts.Item($_)).TotalMinutes -gt $EmailTimeOut)
                                          {$OutageHosts.Remove($_)}
                                    }
                              }
                              else
                              {
                                    # First time down create the list and send email
                                    Write-Host "Adding $_ to OutageHosts."
                                    $OutageHosts = @{$_=(get-date)}
                                    $Now = Get-date
                                    if ($notifyonServerDown)
                                    {
                                          $Body = "$_ has not responded for 5 pings at $Now"
                                          Send-MailMessage -Body "$body" -to $tonotification -from $fromnotification `
                                          -Subject "Host $_ is down" -SmtpServer $smtpserver
                                    }
                              } 
                        }
                  }
            }
            # Report to screen the details
            Write-Host "Available count:"$available.count
            Write-Host "Not available count:"$notavailable.count
            if ($OutageHosts)
            {
                  Write-Host "Not available hosts:"
                  $OutageHosts
            }
            Write-Host ""
            Write-Host "Sleeping $SleepTimeOut seconds"
            Start-Sleep -Seconds $SleepTimeOut
            if ($OutageHosts.Count -gt $MaxOutageCount)
            {
                  # If there are more than a certain number of host down in an hour abort the script.
                  $Exit = $True
                  $body = $OutageHosts | Out-String
                  
                  if ($notifyonMaxOutageCount)
                  {
                        Send-MailMessage -Body "$body" -to $tonotification -from $fromnotification `
                        -Subject "More than $MaxOutageCount Hosts down, monitoring aborted" -SmtpServer $smtpServer
                  }
            }
      }
      while ($Exit -ne $True)
}#End     
}#Start-Monitor




Export-ModuleMember -Function Get-DCSDComputerInfo, Start-Monitor, Test-CompConnection, Get-DCSDAppInfo,Get-DCSDHotFixInfo
