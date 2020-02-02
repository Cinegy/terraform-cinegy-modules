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

function InstallAgent(){
    
	$agentUrl = "https://s3.eu-central-1.amazonaws.com/caas-deploy/v1/Cinegy+Agent+Service+Setup.msi"
	
	Write-Output "Downloading Cinegy Agent from $agentUrl"

    $rootPath = $env:TEMP 
    	
	$client = new-object System.Net.WebClient
	$client.DownloadFile($agentUrl, "$rootPath\Cinegy Agent Service Setup.msi")

    $successCode = 0

	Write-Output "Installing Cinegy Agent"
	
	$svc = Get-Service CinegyAgent
	if($null -ne $svc) 
	{ 
		Write-Output "Cinegy Agent service detected" 
		if($svc.status -eq "Running")
		{
			Write-Output "Stopping service before upgrade"
			$startAgain = $true
			Stop-Service $svc
		}
	}

	Start-Sleep 10
	
	Write-Output "Killing any remaining / hung agent processes before upgrade"
	Stop-Process -ProcessName cinegy.agent* -Force -ErrorAction Ignore
	 
	$successCode = InstallMsi "$rootPath\Cinegy Agent Service Setup.msi"
	
	if($successCode -ne 0) {
		Write-Output "Failed installing Cinegy Agent (will try and restart service anyway)"
	}
	
	Write-Output "Install of Cinegy Agent package complete"
	if($startAgain -eq $true)
	{	
		Write-Output "Restarting previously running Cinegy Agent service"
		Start-Service $svc
	}

    if($successCode -ne 0)
    {
        Write-Output "Error installing - code: " + $successCode 
        
        return $successCode
	}
}

function AddPackages([string] $manifestData)
{
	#Appends (or creates manifest file)
	$manifestPath = "C:\ProgramData\Cinegy\Cinegy Agent Service\products.manifest"

	$manifestData  | Out-File -FilePath $manifestPath -Append

	return
}

function AddDefaultPackages()
{
	#Adds default packages to manifest (abstracted somewhat to make terraform interface cleaner)
	AddPackages($defaultPackages)
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

$defaultPackages = @"
${default_pacakge_manifest}
"@

${injected_content}