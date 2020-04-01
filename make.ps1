 ####### The starting point for the script is the bottom #######

###############################################################
########################## FUNCTIONS ##########################
###############################################################
function All-Command
{
	echo "Checking Module Solution File....."
	$moduleSolutionFile = $env:MOD_NAME + "/" + $env:MOD_ASSEMBLY_NAME + ".sln"
	
	If (!(Test-Path $moduleSolutionFile))
	{
		echo "Module Solution can't be founded"
		return
	}
	
	echo "Check Compiling Environment......"

	if ((CheckForDotnet) -eq 1)
	{
		echo "Compiling Environment Error, DotNet ToolChain can't be founded"
		return
	}

	dotnet build /p:Configuration=Release /nologo
	if ($lastexitcode -ne 0)
	{
		Write-Host "Build failed. If just the development tools failed to build, try installing Visual Studio. You may also still be able to run the game." -ForegroundColor Red
	}
	else
	{
		Write-Host "Build succeeded." -ForegroundColor Green
	}
}

function Clean-Command
{
	If (!(Test-Path "*.sln"))
	{
		return
	}

	if ((CheckForDotnet) -eq 1)
	{
		return
	}

	dotnet clean /nologo
	rm *.dll
	rm mods/*/*.dll
	rm *.dll.config
	rm *.pdb
	rm mods/*/*.pdb
	rm *.exe
	rm ./*/bin -r
	rm ./*/obj -r

	rm $env:ENGINE_DIRECTORY/*.dll
	rm $env:ENGINE_DIRECTORY/mods/*/*.dll
	rm env:ENGINE_DIRECTORY/*.config
	rm env:ENGINE_DIRECTORY/*.pdb
	rm mods/*/*.pdb
	rm env:ENGINE_DIRECTORY/*.exe
	rm env:ENGINE_DIRECTORY/*/bin -r
	rm env:ENGINE_DIRECTORY/*/obj -r
	if (Test-Path env:ENGINE_DIRECTORY/thirdparty/download/)
	{
		rmdir env:ENGINE_DIRECTORY/thirdparty/download -Recurse -Force
	}

	Write-Host "Clean complete." -ForegroundColor Green
}

function CheckForUtility
{
	if (Test-Path $utilityPath)
	{
		return 0
	}

	Write-Host "OpenRA.Utility.exe could not be found. Build the project first using the `"all`" command." -ForegroundColor Red
	return 1
}

function CheckForDotnet
{
	if ((Get-Command "dotnet" -ErrorAction SilentlyContinue) -eq $null) 
	{
		Write-Host "The 'dotnet' tool is required to compile OpenRA. Please install the .NET Core SDK or Visual Studio and try again. https://dotnet.microsoft.com/download" -ForegroundColor Red
		return 1
	}

	return 0
}

function WaitForInput
{
	echo "Press enter to continue."
	while ($true)
	{
		if ([System.Console]::KeyAvailable)
		{
			exit
		}
		Start-Sleep -Milliseconds 50
	}
}

function ReadConfigLine($line, $name)
{
	$prefix = $name + '='
	if ($line.StartsWith($prefix))
	{
		[Environment]::SetEnvironmentVariable($name, $line.Replace($prefix, '').Replace('"', ''))
	}
}

function ParseConfigFile($fileName)
{
	$names = @("BANNERLORD_DIRECTORY", "MOD_NAME", "MOD_ASSEMBLY_NAME", "MOD_FOLDER")

	$reader = [System.IO.File]::OpenText($fileName)
	while($null -ne ($line = $reader.ReadLine()))
	{
		foreach ($name in $names)
		{
			ReadConfigLine $line $name
		}
	}

	$missing = @()
	foreach ($name in $names)
	{
		if (!([System.Environment]::GetEnvironmentVariable($name)))
		{
			$missing += $name
		}
	}

	if ($missing)
	{
		echo "Required mod.config variables are missing:"
		foreach ($m in $missing)
		{
			echo "   $m"
		}
		echo "Repair your mod.config (or user.config) and try again."
		WaitForInput
		exit
	}
}

###############################################################
############################ Main #############################
###############################################################
if ($PSVersionTable.PSVersion.Major -clt 3)
{
    echo "The makefile requires PowerShell version 3 or higher."
    echo "Please download and install the latest Windows Management Framework version from Microsoft."
    WaitForInput
}

echo "================================================="
echo "==============M&B Bannerlord Mod================="
echo "================================================="


$command = "all"

# Load the environment variables from the config file
# and get the mod ID from the local environment variable
ParseConfigFile "mod.config"

$modID = $env:MOD_ID

$env:MOD_SEARCH_PATHS = (Get-Item -Path ".\" -Verbose).FullName + "\mods,./mods"

# Run the same command on the engine's make file
if ($command -eq "all" -or $command -eq "clean")
{
	$bannerlorddir = $env:BANNERLORD_DIRECTORY
	$bannerlordExe = $bannerlorddir + "/bin/Win64_Shipping_Client/bannerlord.exe"
	$bannerlordModName = $env:MOD_NAME

	#$templateDir = $pwd.Path
	#$versionFile = $env:ENGINE_DIRECTORY + "/VERSION"
	#$currentEngine = ""

	#if ($currentEngine -ne "" -and $currentEngine -eq $env:ENGINE_VERSION)
	#{
	#	cd $env:ENGINE_DIRECTORY
	#	Invoke-Expression ".\make.cmd $command"
	#	echo ""
	#	cd $templateDir
	#}
	##elseif ($env:AUTOMATIC_ENGINE_MANAGEMENT -ne "True")
	#{
	#	echo "Automatic engine management is disabled."
	#	echo "Please manually update the engine to version $env:ENGINE_VERSION."
	#	WaitForInput
	#}
	#else
	#{
		echo "Checking Bannerlord Game....."

		if (Test-Path $bannerlordExe)
		{
			All-Command
		}
		else
		{
			echo "Bannerlord Game can't be founded"
		}

		#echo "Downloading engine..."
		#
		#if (Test-Path $env:AUTOMATIC_ENGINE_EXTRACT_DIRECTORY)
		#{
		#	rm $env:AUTOMATIC_ENGINE_EXTRACT_DIRECTORY -r
		#}
		#
		#$url = $env:AUTOMATIC_ENGINE_SOURCE
		#$url = $url.Replace("$", "").Replace("{ENGINE_VERSION}", $env:ENGINE_VERSION)
		#
		#mkdir $env:AUTOMATIC_ENGINE_EXTRACT_DIRECTORY > $null
		#$dlPath = Join-Path $pwd (Split-Path -leaf $env:AUTOMATIC_ENGINE_EXTRACT_DIRECTORY)
		#$dlPath = Join-Path $dlPath (Split-Path -leaf $env:AUTOMATIC_ENGINE_TEMP_ARCHIVE_NAME)
		#
		#$client = new-object System.Net.WebClient
		#[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
		#$client.DownloadFile($url, $dlPath)
		#
		#Add-Type -assembly "system.io.compression.filesystem"
		#[io.compression.zipfile]::ExtractToDirectory($dlPath, $env:AUTOMATIC_ENGINE_EXTRACT_DIRECTORY)
		#rm $dlPath
		#
		#$extractedDir = Get-ChildItem $env:AUTOMATIC_ENGINE_EXTRACT_DIRECTORY -Recurse | ?{ $_.PSIsContainer } | Select-Object -First 1
		#Move-Item $extractedDir.FullName -Destination $templateDir
		#Rename-Item $extractedDir.Name (Split-Path -leaf $env:ENGINE_DIRECTORY)
		#
		#rm $env:AUTOMATIC_ENGINE_EXTRACT_DIRECTORY -r
		#
		#cd $env:ENGINE_DIRECTORY
		#Invoke-Expression ".\make.cmd version $env:ENGINE_VERSION"
		#Invoke-Expression ".\make.cmd $command"
		#echo ""
		#cd $templateDir
	#}
}

$utilityPath = $env:ENGINE_DIRECTORY + "/OpenRA.Utility.exe"
$styleCheckPath = $env:ENGINE_DIRECTORY + "/OpenRA.StyleCheck.exe"

$execute = $command
if ($command.Length -gt 1)
{
	$execute = $command[0]
}

# In case the script was called without any parameters we keep the window open
if ($args.Length -eq 0)
{
	WaitForInput
}