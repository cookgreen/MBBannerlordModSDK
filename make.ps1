 ####### The starting point for the script is the bottom #######

###############################################################
########################## FUNCTIONS ##########################
###############################################################

function Copy-Bannerlord-Dlls
{
	echo "Copying Bannerlord Assemblies to the Module Lib Directory......"
	
	if(!(Test-Path "lib"))
	{
		New-Item -Path "." -Name "lib" -ItemType "directory"
	}
	
	$bannerlodBinDir = $env:BANNERLORD_DIRECTORY + "\\bin\\Win64_Shipping_Client\\";
	
	$bannerlodDlls = $bannerlodBinDir + "*.dll"
	copy $bannerlodDlls "lib\\" -Force
	
	$bannerlodExes = $bannerlodBinDir + "*.exe"
	copy $bannerlodExes "lib\\" -Force
}

function All-Command
{
	echo "Checking Module Solution File....."
	$moduleSolutionFile = $env:MOD_ASSEMBLY_NAME + ".sln"
	
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

	echo "Compiling....."
	dotnet build /p:Configuration=Release /nologo
	if ($lastexitcode -ne 0)
	{
		Write-Host "Build failed. If just the development tools failed to build, try installing Visual Studio. You may also still be able to run the game." -ForegroundColor Red
	}
	else
	{
		Write-Host "Build succeeded." -ForegroundColor Green
		
		echo "Copy Module to the Bannerlord Directory......."
		$src = "bin\\" + $env:MOD_ASSEMBLY_NAME + ".dll"
		$dest = $env:MOD_FOLDER + "\\bin\\Win64_Shipping_Client\\" + $env:MOD_ASSEMBLY_NAME + ".dll"
		copy $src $dest -Force
		
		$src = $env:MOD_FOLDER + "\*"
		$dest = $env:BANNERLORD_DIRECTORY + "\\Modules\\" + $env:MOD_FOLDER + "\\"
		copy $src $dest -Recurse -Force
		
		echo "Done!"
	}
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

	echo "Checking Bannerlord Game....."

	if (Test-Path $bannerlordExe)
	{
		Copy-Bannerlord-Dlls
		
		All-Command
	}
	else
	{
		Write-Host "Bannerlord Game can't be founded" -ForegroundColor Green
	}
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