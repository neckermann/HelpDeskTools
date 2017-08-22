function Test-CompConnection($computer){
    $works=$true
    if (Test-Connection $computer -Count 1 -Quiet){
        try{
            Get-WmiObject -Class win32_bios -ComputerName $computer -ErrorAction Stop | Out-Null
        }catch{
            $works=$false
            Write-Host 'Was not able to connect to WMI Service Computer/IP you entered. Check firewall settings'
        }

    }else{
        Write-Host 'Was not able to connect to the Computer/IP you entered. Check the computer is on.'
        $works=$false
    }
    return $works
}


function Get-ComputerInfo {
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
            $props=@{
                    'Computer Name'=$cs.name;
                    'Computer Manufacture'=$cs.manufacture;
                    'Computer Model'=$cs.model;
                    'Computer Serial'=$sysenc.SerialNumber;
                    'Computer Asset'=$sysenc.SMBIOSAssetTag;
                   }
               $obj=New-Object -TypeName PSObject -Property $props 
               Write-Output $obj
            }
        }
    }
    END{}

}
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

Export-ModuleMember -Function Get-ComputerInfo
