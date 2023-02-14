#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Module Cobalt

$computerName = "winbox"
$appSource = "WinGet"
$apps = @(
	@{ id = "AgileBits.1Password"; name = "1Password" },
	@{ id = "EpicGames.EpicGamesLauncher"; name = "Epic Games Launcher" },
	@{ id = "Mozilla.Firefox"; name = "Firefox" },
	@{ id = "OpenWhisperSystems.Signal"; name = "Signal" },
	@{ id = "9PF08LJW7GW2"; name = "Hey Mail" },
	@{ id = "OpenRA.OpenRA"; name = "OpenRA" },
	@{ id = "GOG.Galaxy"; name = "GOG Galaxy" },
	@{ id = "Valve.Steam"; name = "Steam" },
	@{ id = "25286HaoyuanLiu.FluentReader_5bmsqm5p4m2q6"; name = "Fluent Reader" },
	@{ id = "ScooterSoftware.BeyondCompare4"; name = "Beyond Compare 4" },
	@{ id = "Microsoft.Teams"; name = "Microsoft Teams" },
	@{ id = "Git.Git"; name = "Git" },
	@{ id = "GitHub.cli"; name = "GitHub CLI" },
	@{ id = "Microsoft.VisualStudioCode"; name = "Visual Studio Code" }
)
$overwritingCharacter = " "
$rebootNeeded = $false

Write-Host "Setting computer name: " -NoNewline
if ($env:COMPUTERNAME -ne $computerName) {
	Rename-Computer -NewName $computerName
	$rebootNeeded = $true
}
Write-Host "Done."

Write-Host "Making sure System Restore is turned on: " -NoNewline
if ($null -eq (Get-ComputerRestorePoint)) {
	Enable-ComputerRestore -Drive "C:\"
}
Write-Host "Done."

Write-Host "Creating system restore point: " -NoNewline
$restorePointName = $MyInvocation.MyCommand.Name
$timestamp = Get-Date -Format o
Checkpoint-Computer -Description "${restorePointName}: $timestamp" -RestorePointType APPLICATION_INSTALL
Write-Host "Done."

#Write-Host "Adding US-International keyboard layout: " -NoNewline
#$languageSettings = (Get-WinUserLanguageList)
# for each language
#  if language is en-*
#   Add InputMethodTips 0409:00020409
#Write-Host "Done."

Write-Host "Installing applications:"
foreach ($app in $apps) {
	Write-Host "`t$($app.name): " -NoNewline
	
	$packageDetails = Get-WinGetPackage -ID $app.id -Exact
	if ($null -ne $packageDetails) {
		Write-Host "Already installed."
	} else {
		$cursorPosition = $host.UI.RawUI.CursorPosition

		Write-Host "Not installed. " -NoNewline
		$lineLength = $host.UI.RawUI.CursorPosition.X - $cursorPosition.X
		$host.UI.RawUI.CursorPosition = $cursorPosition

		$packageAvailable = Find-WinGetPackage -ID $app.id -Exact
		if ($null -eq $packageAvailable) {
			Write-Host "Application not available from $appSource."
		} else {
			Write-Host "Application found in $appSource. " -NoNewline
			$lineLength = $host.UI.RawUI.CursorPosition.X - $cursorPosition.X
			$host.UI.RawUI.CursorPosition = $cursorPosition

			Install-WinGetPackage -ID $app.id -Exact
			$host.UI.RawUI.CursorPosition = $cursorPosition

			Write-Host "installed." -NoNewline
			$charsToOverwrite = [math]::Max(0, $lineLength - ($host.UI.RawUI.CursorPosition.X - $cursorPosition.X))
			$overwriteString = $overwritingCharacter * $charsToOverwrite
			Write-Host $overwriteString
		}
	}
}

if ($rebootNeeded) {
	Restart-Computer
}
