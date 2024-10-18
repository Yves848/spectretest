[system.console]::CursorVisible = $false

[system.Console]::Clear()
Write-SpectreRule -Title "Get Winget Installed Packages" -Alignment Center
$list = invoke-SpectreCommandWithStatus -Spinner Dots -Title "Get Packages"  -ScriptBlock{
  return  Get-WinGetPackage
}

$script:i = 0
$script:skip = 0
$partial = ($list | Select-Object -skip ($script:skip) -First ($Host.UI.RawUI.BufferSize.Height -7))
function buildItem {
  param (
    [psCustomObject]$Object,
    [String]$field
  )
  $string = $Object.$field
  $index = $partial.indexof($Object)
  if ($index -eq $script:i) {
     return (Build-Candy "<White>$($string)</White>")
  } else {
    return (Build-Candy "<Green>$($string)</Green>")
  }

}

[system.Console]::Clear()
$properties = @( @{'Name'= "Package $($script:skip)"; Expression = {buildItem -Object $_ -field "Name"} ;width = 80})
$redraw = $true
$stop = $false
while (-not $stop) {
  if ($redraw) {
    $partial = ($list | Select-Object -skip ($script:skip) -First ($Host.UI.RawUI.BufferSize.Height -7))
    Format-SpectreTable -Data $partial -Property $properties | Out-SpectreHost
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
