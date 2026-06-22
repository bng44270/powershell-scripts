class SecurePassword {
  [securestring] $Password
  [int32] $RandomLength
  [pscustomobject] $RandomChars = @{
    alpha   = "ABCDEFGHJKMNPQRSTWXYZ"
    nums    = "0123456789"
    special = "`$%&*+=#@!?~"
  }

  SecurePassword() {  }

  static [SecurePassword] SetPassword([SecureString]$p) {
    $n = [SecurePassword]::new()
    $n.Password = $p
    return $n
  }

  static [SecurePassword] SetPasswordFromText([string]$p) {
    $n = [SecurePassword]::new($p)
    $n.Password = ($p | ConvertTo-SecureString -AsPlainText -Force)
    return $n
  }

  static [SecurePassword] NewRandomPassword([Int32]$r) {
    $n = [SecurePassword]::new()
    $n.RandomLength = $r
    $n.GenerateRandom()
    return $n
  }

  static [SecurePassword] NewRandomPassword() {
    $n = [SecurePassword]::new()
    $n.RandomLength = 32
    $n.GenerateRandom()
    return $n
  }

  [string] Get() {
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($this.Password)
    $returnValue = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)

    return $returnValue
  }

  [string] GetRandomCharString() {
    return ($this.RandomChars.alpha + $this.RandomChars.nums + $this.RandomChars.special + $this.RandomChars.alpha.ToLower())
  }

  [bool] ValidateRandom([string] $p) {
    $hasAlphaLow = $false
    $hasAlphaUpper = $false
    $hasNumber = $false
    $hasSpecial = $false

    $passAr = ($p -split "") 
    $alphaLowAr = ($this.RandomChars.alpha.ToLower() -split "")
    $alphaUpperAr = ($this.RandomChars.alpha -split "")
    $numberAr = ($this.RandomChars.nums -split "")
    $specialAr = ($this.RandomChars.special -split "")

    for ($i = 0; $i -lt $passAr.Length; $i++) {
      if ((-not $hasAlphaLow) -and ($passAr[$i] -in $alphaUpperAr)) {
        $hasAlphaLow = $true
      }

      if ((-not $hasAlphaUpper) -and ($passAr[$i] -in $alphaLowAr)) {
        $hasAlphaUpper = $true
      }

      if ((-not $hasNumber) -and ($passAr[$i] -in $numberAr)) {
        $hasNumber = $true
      }

      if ((-not $hasSpecial) -and ($passAr[$i] -in $specialAr)) {
        $hasSpecial = $true
      }
    }

    return ($hasAlphaLow -and $hasAlphaUpper -and $hasNumber -and $hasSpecial)
  }

  [void] GenerateRandom() {
    $useChars = $this.GetRandomCharString()
    $randpass = ""
  
    while ($true) {	
      $counter = 0
    
      $rand = [System.Random]::new()
      while ($counter -lt $this.RandomLength) {
        $randpass += $useChars[$rand.next(0, ($useChars.Length - 1))]
        $counter++
      }

      if ($this.ValidateRandom($randpass)) {
        break
      }
      else {
        $randpass = ""
      }
    }
    
    $this.Password = ($randpass | ConvertTo-SecureString -AsPlainText -Force)
  }
}

class Range : System.Collections.ArrayList {
  Range([Int32] $Count) : base() {
    $this.build(0, 1, $Count)
  }

  Range([Int32] $Start, [Int32] $Count) : base() {
    $this.build($Start, 1, $Count)
  }

  Range([Int32] $Start, [Int32] $Step, [Int32] $Count) : base() {
    $this.build($Start, $Step, $Count)
  }

  hidden [void] build([Int32] $Start, [Int32] $Step, [Int32] $Count) {
    for ($i = 0; $i -lt $Count; $i++) {
      $this.Add($Start)
      $Start += $Step
    }
  }
}

class SimpleMath {
  static [double] Sum([System.Collections.ArrayList]$Numbers) {
    [double] $tot = 0
    $Numbers | ForEach-Object {
      $tot += ([double]$_)
    }
    return $tot
  }

  static [double] Average([System.Collections.ArrayList]$Numbers) {
    $tot = [SimpleMath]::Sum($Numbers)
    return ($tot / ($Numbers.Count))
  }
}

class MiscTools {
  static [string] Int2Hex([Int64]$i) {
    return ([Convert]::ToString($i,16))
  }
  
  static [string] Int2Bin([Int64]$i) {
    return ([Convert]::ToString($i,2))
  }
  
  static [string] Str2Hex([string]$s) {
    return (([System.Text.Encoding]::UTF8.GetBytes($s) | % { [Convert]::ToString($_,16) }) -join '')
  }
  
  static [string] Str2Bin([string]$s) {
    return (([System.Text.Encoding]::UTF8.GetBytes($s) | % { [Convert]::ToString($_,2) }) -join '')
  }
  
  static [string] FormatInt([Int64]$i) {
    $ar = ([string]$i).toCharArray()
    [System.Array]::Reverse($ar)
    $newAr = [System.Text.RegularExpressions.Regex]::Replace( -join ($ar), "([0-9]{3})", "`$1,").toCharArray()
    [System.Array]::Reverse($newAr)
    return (-join ($newAr) -replace "^,", "")
  }
}

enum TimeSpanUnits {
  Milliseconds = 0
  Seconds = 1
  Minutes = 2
  Hours = 3
  Ticks = 4
}

function Measure-Performance([TimeSpanUnits] $Unit, [scriptblock] $Code = {}, [Int32] $Attempts = 1) {
  $TimeSpanUnitValues = @("TotalMilliseconds", "TotalSeconds", "TotalMinutes", "TotalHours", "Ticks")
  $useunit = $TimeSpanUnitValues[$Unit]

  $samples = [System.Collections.ArrayList]::new()

  for ($i = 1 ; $i -le $Attempts; $i++) {
    $startsec = (Get-Date).TimeOfDay."$useunit"
    & $Code
    $endsec = (Get-Date).TimeOfDay."$useunit"

    $elapse = ([double]($endsec - $startsec))
    
    [void] $samples.Add($elapse)
    
    Start-Sleep -Seconds 1
  }

  $average = [System.Math]::Round([SimpleMath]::Average($samples), 3)

  $returnValue = [pscustomobject]@{
    "Average" = $average
    "Units" = ($TimeSpanUnitValues[$Unit] -replace '^Total', '')
    "Attempts" = $Attempts
    "Values" = $samples
    "Code" = $Code
  }
  
  $returnValue | Add-Member -MemberType ScriptMethod -Name ReRun -Value {
    & ([ScriptBlock]::Create("Measure-Performance -Unit " + $this.Units + " -Code {" + $this.Code.ToString() + "} -Attempts " + $this.Attempts))
  }
  
  return $returnValue
}

function ConvertFrom-Xml([string] $File=$null) {
  begin {
    if (-not $File) {
      $data = ""
    }
  }
  process {
    if (-not $File) {
      $data += $_
    }
  }
  end {
    if (-not $File) {
      [xml]($data)
    }
    else {
      [xml]([string](Get-Content $File))
    }
  }
}

function Add-Path($Directory=$null) {
  process {
    $checkPath = (-not $Directory) ? $_ : $Directory
    
    if (-not ($checkPath -in ($env:Path -split ';'))) {
      $env:Path += (";" + $checkPath)
    }
  }
}

function Start-SshSession() {
  $windowSize = [System.Drawing.Size]::new(230, 250)
  $win = [AppWindow]::new($windowSize)

  $win.Text = "SSH Client"
  $win.ControlBox = $false

  $labelSize = [System.Drawing.Size]::new(80, 40)
  $textSize = [System.Drawing.Size]::new(100, 40)

  $hostLabelLoc = [System.Drawing.Point]::new(10, 10)
  $win.AddLabel("lblHostname", $hostLabelLoc, $labelSize, "Hostname")

  $userLabelLoc = [System.Drawing.Point]::new(10, 60)
  $win.AddLabel("lblUsername", $userLabelLoc, $labelSize, "Username")

  $hostTextLoc = [System.Drawing.Point]::new(90, 10)
  $win.AddTextBox("txtHostname", $hostTextLoc, $textSize)
  
  $userTextLoc = [System.Drawing.Point]::new(90, 60)
  $win.AddTextBox("txtUsername", $userTextLoc, $textSize)

  $buttonLoc = [System.Drawing.Point]::new(40, 100)
  $buttonSize = [System.Drawing.Size]::new(80, 40)
  $win.AddButton("btnConnect", $buttonLoc, $buttonSize, "Connect")

  $win.Elements['btnConnect'].Add_Click({
    $sshuser = $win.Elements['txtUsername'].Text
    $sshhost = $win.Elements['txtHostname'].Text
    
    Start-Process -FilePath C:\Windows\System32\cmd.exe -ArgumentList @("/C", "ssh", "$sshuser@$sshhost")

    $win.Elements['txtHostname'].Text = ""
    $win.Elements['txtUsername'].Text = ""
  })
  
  $exitButtonLoc = [System.Drawing.Point]::new(40, 160)
  $win.AddButton("btnExit",$exitButtonLoc, $buttonSize, "Exit")
  
  $win.Elements['btnExit'].Add_Click({
    Stop-Process -Id $global:PID
  })

  $win.Open()
}

function Show-Confirm($Message="") {
  Write-Host -NoNewline "$Message "
  return ([System.Console]::ReadKey($true))
}

function Get-DiskUtilization($DriveLetter="C") {
	Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DeviceID -eq ($DriveLetter + ":") } |ForEach-Object {
		[pscustomobject]@{
			DriveLetter = $_.DeviceID
			FreeSpace = $_.FreeSpace
			UsedSpace = ($_.Size - $_.FreeSpace)
			TotalSpace = $_.Size
			PercentFree = [System.Math]::Round((($_.FreeSpace/$_.Size)*100),2)
			PercentUsed = [System.Math]::Round(((($_.Size - $_.FreeSpace)/$_.Size)*100),2)
		}
	}
}

