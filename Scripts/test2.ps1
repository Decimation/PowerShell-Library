#requires -Module Microsoft.PowerShell.ConsoleGuiTools
using namespace Terminal.Gui

## Load the required assemblies
$guiTools = (Get-Module Microsoft.PowerShell.ConsoleGuiTools -List).ModuleBase
Add-Type -Path (Join-path $guiTools Terminal.Gui.dll)

## Initialize our application
[Application]::Init()

## Create a window with a label and a button
$window = [Window] @{
    Title = 'Hello Window Title!'
    Height = 20
    Width = 50
}

$label = [Label] @{
    X = [Pos]::Center(); Y = [Pos]::Center() - 1
    Width = 11
    Text = 'Hello World'
}
$window.Add($label)

$button = [Button] @{
    X = [Pos]::Center(); Y = [Pos]::Center() + 1
    Text = 'OK'
}
$button2 = [Button] @{
	X = [Pos]::Right($button);
	Y = [Pos]::Center() + 1
	Text = 'OK'
}
$window.Add($button,$button2)

## Console windows doesn't have any features that let applications close
## by default (like Alt+F4 does on a Windows Forms application),
## so associate this with the "OK" button.
$button.add_Clicked({ [Application]::RequestStop() })

## Add the window to the application and run it.
[Application]::Top.Add($window)
[Application]::Run()

## Our script gets here once the user clicks the "OK" button
[Application]::Shutdown()