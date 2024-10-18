using module psCandy

[system.console]::CursorVisible = $false

[system.Console]::Clear()
Write-SpectreRule -Title "Get Winget Installed Packages" -Alignment Center
$list = invoke-SpectreCommandWithStatus -Spinner Dots -Title "Get Packages"  -ScriptBlock{
  $list = Get-WinGetPackage | Where-Object {$_.Source -eq "winget"}
  # $list = Find-WinGetPackage -Query "code" | Where-Object {$_.Source -eq "winget"}
  return $list
}

$script:i = 0
$script:skip = 0
$partial = ($list | Select-Object -skip ($script:skip) -First ($Host.UI.RawUI.BufferSize.Height -5))
function buildItem {
  param (
    [psCustomObject]$Object,
    [String]$field,
    [int]$width
  )
  [string]$string = $($Object.$field)
  $string =  [candyString]::PadString($string,$width," ", [Align]::Left)
  
  $index = $partial.indexof($Object)
  if ($index -eq $script:i) {
    #  return (Build-Candy "<White><Underline>$($string)</White>")
    return "[Underline]$($string)[/]"
  } else {
    return ("[Green]$($string)[/]")
  }

}

[system.Console]::Clear()

$redraw = $true
$stop = $false
while (-not $stop) {
  if ($redraw) {
    $properties = @( @{"Name" = ""; Expression = {""}; width = 1},
                     @{'Name'= "Package $($script:skip)"; Expression = {buildItem -Object $_ -field "Name" -width 50} },
                     @{"Name" = "Id"; Expression = {buildItem -Object $_ -field "Id" -width 30}})
    $partial = ($list | Select-Object -skip ($script:skip) -First ($Host.UI.RawUI.BufferSize.Height -5))
    Format-SpectreTable -Data $partial -Property $properties -AllowMarkup  | Out-SpectreHost
    [system.console]::SetCursorPosition(0, 0)
    [system.console]::CursorVisible = $false
    $redraw = $false
  }  
  
  if ($global:Host.UI.RawUI.KeyAvailable) {
    [System.Management.Automation.Host.KeyInfo]$key = $($global:host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'))
    switch ($key.VirtualKeyCode) {
      27 { $stop = $true} # ESC key to exit
      38 {
        # Up
        
        $script:i--
        if ($script:i -lt 0) { 
          $script:i = 0
          if ($script:skip -gt 0) {
          $script:skip--
          }
        }
        $redraw = $true
        
      }
      40 {
        # Down
        
        $script:i++
        if ($script:i -ge $partial.count) { 
          $script:i = $partial.count -1
          $script:skip++
        }
        $redraw = $true
        
      }
    }
  }
}


[system.console]::CursorVisible = $true
[system.console]::Clear()
