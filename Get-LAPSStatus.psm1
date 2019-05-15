
<# Work in progress


function Get-LAPSStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,
                [Parameter(ParameterSetName="SearchBase")]
        [string[]]$SearchBase
    )
    BEGIN{}
    PROCESS{


if ($SearchBase){
$missing = (Get-ADComputer -Filter * -Properties * -SearchBase $SearchBase |Where-Object {($_.'ms-Mcs-AdmPwd' -eq $null) -and ($_.'OperatingSystem' -notlike "*server*")}).count
$installed = (Get-ADComputer -Filter * -Properties * -SearchBase $SearchBase |Where-Object {($_.'ms-Mcs-AdmPwd' -ne $null) -and ($_.'OperatingSystem' -notlike "*server*")}).count
$props =[ordered] @{

    'LAPS Installed' = $installed
    'LAPS Missing' = $missing
}       

            
               $obj=New-Object -TypeName PSObject -Property $props 
               Write-Output $obj
            }
        }
    }
    END{}
}

#>

#Get the status of your Local Administrator Password Solution (LAPS) Deployment.
#Below can be used on it's own at this point.

$SearchBase = "ou=cfbcomputers,dc=cfbank,dc=com"
#SearchBase is the root directory to look for the computer objects. It will recurse down the OU structure.
$LogFilePath = "\\Server\Share"
#LogFilePath is the directory where the log files will be kept.
$SleepTime = 86400
#How often the script is run to gather the data and update the Status and other Documents. It defaults to 24hrs.


while(1){

#Gather the computer objects based on the $SearchBase parameter. We are also excluding Servers in this script, but if you want to remove them from exclusion you can just change
# the -notlike to -like in the Where-Object filter "*server*"
$TotalMissing = (Get-ADComputer -Filter * -Properties * -SearchBase $SearchBase|
Where-Object {($_.'ms-Mcs-AdmPwd' -eq $null) -and ($_.'OperatingSystem' -notlike "*server*") -and ($_.'OperatingSystem' -like "*windows*")}).count
$TotalInstalled = (Get-ADComputer -Filter * -Properties * -SearchBase $SearchBase|
Where-Object {($_.'ms-Mcs-AdmPwd' -ne $null) -and ($_.'OperatingSystem' -notlike "*server*") -and ($_.'OperatingSystem' -like "*windows*")}).count


$computerswithout = (Get-ADComputer -Filter * -Properties * -SearchBase $SearchBase|
Where-Object {($_.'ms-Mcs-AdmPwd' -eq $null) -and ($_.'OperatingSystem' -notlike "*server*") -and ($_.'OperatingSystem' -like "*windows*")}).name
$computerswith = (Get-ADComputer -Filter * -Properties * -SearchBase $SearchBase|
Where-Object {($_.'ms-Mcs-AdmPwd' -ne $null) -and ($_.'OperatingSystem' -notlike "*server*") -and ($_.'OperatingSystem' -like "*windows*")}).name

        $propsStatus =[ordered] @{
            'Date' = Get-Date
            'LAPS Installed' = $TotalInstalled
            'LAPS Missing' = $TotalMissing
    
            }
        $objStatus=New-Object -TypeName PSObject -Property $propsStatus
        Write-Output $objStatus

        #Output the number of computers with or without LAPS
        Write-Output $objStatus|Export-Csv -NoTypeInformation -Path "$LogFilePath\LAPSStatus.csv" -Append

#Output the names of the computers with or without LAPS installed to a txt file.
$computerswithout|Out-File "$LogFilePath\LAPSComputersMissing.txt" -Force
$computerswith|Out-File "$LogFilePath\LAPSComputersInstalled.txt" -Force

        #Get detailed information about the computers missing LAPS. Maybe they are old objects in AD that need removed or that the LAPS GPO is not applied to the OU they are located in.
        $Computers=Get-Content "$LogFilePath\LAPSComputersMissing.txt"
        Remove-Item -Path "$LogFilePath\LAPSComputersMissingDetails.csv"
        foreach ($Computer in $Computers){
            Get-ADComputer -Identity $Computer -Properties *|select Enabled,Name, LastLogonDate, Modified, DistinguishedName|Export-Csv -NoTypeInformation "$LogFilePath\LAPSComputersMissingDetails.csv" -Append




        }


Start-Sleep $SleepTime

}


