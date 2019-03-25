#Requires -RunAsAdministrator

function RenameHost(){
	
	#Perform rename using 'hostname' tag from AWS metadat
	$taggedName = Get-LocalInstanceTagValue("Hostname")

	if($null -ne $taggedName)
	{
		if($taggedName -ne "")
		{
			Rename-Computer -NewName $taggedName -Force 
		}
	}

    return
}

function InstallMsi([string] $msiName)
{
    Write-Host "Going to run MSI $msiName"

    $install = Start-Process $msiName -ArgumentList "/quiet /qn" -Wait -PassThru

    if ($install.ExitCode -ne 0) {
        Write-Host "An error occurred while installing [$msiName]. Exit Code was " $install.ExitCode
    }

    return ($install.ExitCode)
}


function Get-LocalInstanceTagValue([string] $tagName)
{
	$result = Invoke-WebRequest -Uri http://169.254.169.254/latest/dynamic/instance-identity/document
	$meta = ConvertFrom-Json($result.Content)
	$instanceId = $meta.instanceId
	
	if($null -eq $instanceId) 
	{
		Write-Host "Cannot access and / or parse AWS metadata - are you really running in AWS?"
		exit
	}
	
	$localtags = get-ec2tag  -Filter @{ Name="resource-id"; Values=$instanceId }

	return $localTags.Where({$_.Key -eq "Hostname"}).Value
}

${injected_content}