$LibPath = "$(System.DefaultWorkingDirectory)/_ScheduledTaskManagement/ScheduledTaskManagement.ps1"
Import-Module $LibPath

Function Create-ScheduledTask1
{
	param(
        [Parameter(Position=0, Mandatory=$False, ValueFromPipeline=$True)]
		[string]$ComputerName = "localhost",

        [Parameter(Position=1, Mandatory=$False, ValueFromPipeline=$True)]
		[string]$RunAsUser="System",

        [Parameter(Position=2, Mandatory=$False, ValueFromPipeline=$True)]
		[string]$RunAsUserPassword,

        [Parameter(Position=3, Mandatory=$True, ValueFromPipeline=$True)]
		[string]$TaskName,

        [Parameter(Position=4, Mandatory=$True, ValueFromPipeline=$True)]
		[string]$TaskLocation,

        [Parameter(Position=5, Mandatory=$True, ValueFromPipeline=$True)]
		[string]$TaskRun,

        [Parameter(Position=6, Mandatory=$True, ValueFromPipeline=$True)]
		[string]$Schedule = "Daily",

        [Parameter(Position=7, Mandatory=$True, ValueFromPipeline=$True)]
		[string]$StartTime,

        [Parameter(Position=8, Mandatory=$True, ValueFromPipeline=$True)]
		[string]$EndTime,

        [Parameter(Position=9, Mandatory=$True, ValueFromPipeline=$True)]
		[string]$Interval = "1",

		[Parameter(Position=10, Mandatory=$False, ValueFromPipeline=$True)]
		[string]$StartDate,

		[Parameter(Position=11, Mandatory=$False, ValueFromPipeline=$True)]
		[string]$Parameters,

        [Parameter(Position=12, Mandatory=$False, ValueFromPipeline=$True)]
		[string]$HighestRunLevel = $false,

        [Parameter(Position=13, Mandatory=$False, ValueFromPipeline=$True)]
		[switch]$Indefinently
	)
    $taskLocationAndName = Join-Path $TaskLocation $TaskName

    $cmdRunAsUser = if((-not [string]::IsNullOrWhiteSpace($RunAsUser)) -and (-not [string]::IsNullOrWhiteSpace($RunAsUserPassword))){"/ru '$RunAsUser' /rp '$RunAsUserPassword'"} else {''}

    if($RunAsUser -match 'System') {
        $cmdRunAsUser = "/ru $RunAsUser"
    }

	# Case insensitive by default; different tasks require different sets of parameters
	switch ($Schedule)
    {
        "Daily"
                {
                    if (!($Indefinently))
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /et $EndTime /F"
                    }
                    else
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /F"
                    }
                }
        "Hourly"
                {
                    if (!($indefinently))
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /et $EndTime /F"
                    }
                    else
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /F"
                    }
                }
        "Minute"
                {
                    if (!($indefinently))
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /et $EndTime /F"
                    }
                    else
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /F"
                    }
                }
        "Once"
                {
                    $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /st $StartTime /F"
                }
        "Weekly"
                {
                    if (!($indefinently))
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /et $EndTime /F"
                    }
                    else
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /F"
                    }
                }
        "Monthly"
                {
                    if (!($indefinently))
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /et $EndTime /F"
                    }
                    else
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /F"
                    }
                }
        default {
                    if (!($indefinently))
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /et $EndTime /F"
                    }
                    else
                    {
                        $Command = "schtasks.exe /create $cmdRunAsUser /s `"$ComputerName`" /tn `"$taskLocationAndName`" /tr `"$TaskRun $Parameters`" /sc $Schedule /mo $Interval /st $StartTime /F"
                    }
                }
    }

	if ($StartDate)
	{
		$Command += " /sd `"$StartDate`""
	}

    if ($HighestRunLevel -eq "TrUe")
    {
        $Command += " /RL HIGHEST"
    }

	Invoke-Expression $Command
}

$TaskFolder = "PAC"
$TaskName = "$(Release.EnvironmentName)_pac_fillplates_task"
$Exe = "$(TargetFolder)\FillPlates.exe"
$RunAsUser = "$(RunAsUser)"
$RunAsUserPassword = '$(RunAsUserPassword)'
$ComputerName = "localhost"
$Schedule = "Daily"
$StartTime = '02:15'
$Interval = "1"
$Indefinently = $true

if ((Exists-ScheduledTask -ComputerName $ComputerName -TaskName $TaskName -TaskLocation $TaskFolder) -eq $true)
{
	Remove-ScheduledTask -ComputerName $ComputerName -TaskName $TaskName -TaskLocation $TaskFolder
}
Create-ScheduledTask1 -ComputerName $ComputerName -TaskName $TaskName -TaskLocation $TaskFolder -TaskRun $Exe -Schedule $Schedule -Interval $Interval -StartTime $StartTime -Indefinently $Indefinently -RunAsUser $RunAsUser -RunAsUserPassword $RunAsUserPassword