################
# Add the following statements before loading appwindow.psm1 module (paths to DLL's may vary)
#
#     using assembly "C:\Windows\Microsoft.NET\Framework\v4.0.30319\System.Windows.Forms.dll"
#     using assembly "C:\Windows\Microsoft.NET\Framework\v4.0.30319\System.Drawing.dll"
#     using assembly "C:\Windows\Microsoft.NET\Framework\v4.0.30319\Microsoft.VisualBasic.dll"
################

class AppWindow : System.Windows.Forms.Form {
    [System.Collections.Hashtable] $Elements

    AppWindow([System.Drawing.Size] $s) : base() {
        $this.Elements = [System.Collections.Hashtable]::new()
        $this.Size = $s
    }

    [void] AddLabel([string] $n, [System.Drawing.Point] $l, [System.Drawing.Size] $s, [string] $t) {
        $d = [System.Windows.Forms.Label]::new()
        $d.Location = $l
        $d.Size = $s
        $d.Text = $t

        $this.Elements[$n] = $d
        $this.Controls.Add($d)
    }

    [void] AddTextBox([string] $n, [System.Drawing.Point] $l, [System.Drawing.Size] $s) {
        $b = [System.Windows.Forms.TextBox]::new()
        $b.Location = $l
        $b.Size = $s

        $this.Elements[$n] = $b
        $this.Controls.Add($b)
    }

    [void] AddButton([string] $n, [System.Drawing.Point] $l, [System.Drawing.Size] $s, [string] $t) {
        $b = [System.Windows.Forms.Button]::new()
        $b.Location = $l
        $b.Size = $s
        $b.Text = $t
        
        $this.Elements[$n] = $b
        $this.Controls.Add($b)
    }

    [void] Open() {
        $this.Topmost = $true
        $this.ShowDialog() | Out-Null
    }

    [void] Close() {
        $this.Dispose()
    }

    static [AppWindow] FromJson([string] $p) {
        $json = (Get-Content $p | ConvertFrom-Json)

        $formSize = [System.Drawing.Size]::new($json.size.width, $json.size.height)
        
        $w = [AppWindow]::new($formSize)

        $json.elements | ForEach-Object {
            $thisElem = $_

            if ($thisElem.type -eq "label") {
                $name = $thisElem.name
                $size = [System.Drawing.Size]::new($thisElem.size.width, $thisElem.size.height)
                $loc = [System.Drawing.Point]::new($thisElem.loc.x, $thisElem.loc.y)
                $labeltext = $thisElem.text

                $w.AddLabel($name, $loc, $size, $labeltext)
            }
            elseif ($thisElem.type -eq "textbox") {
                $name = $thisElem.name
                $size = [System.Drawing.Size]::new($thisElem.size.width, $thisElem.size.height)
                $loc = [System.Drawing.Point]::new($thisElem.loc.x, $thisElem.loc.y)
                $w.AddTextBox($name, $loc, $size)
            }
            elseif ($thisElem.type -eq "button") {
                $name = $thisElem.name
                $size = [System.Drawing.Size]::new($thisElem.size.width, $thisElem.size.height)
                $loc = [System.Drawing.Point]::new($thisElem.loc.x, $thisElem.loc.y)
                $label = $thisElem.text

                $w.AddButton($name, $loc, $size, $label)
            }
        }

        return $w
    }

    static [void] ShowMessage([string]$m, [string]$t) {
        [System.Windows.Forms.MessageBox]::Show($m, $t, [System.Windows.Forms.MessageBoxButtons]::OK)
    }

    static [void] ShowMessage([string]$m, [string]$t, [System.Windows.Forms.MessageBoxIcon]$i) {
        [System.Windows.Forms.MessageBox]::Show($m, $t, [System.Windows.Forms.MessageBoxButtons]::OK, $i)
    }

    static [bool] ShowConfirm([string]$m, [string]$t) {
        $r = [System.Windows.Forms.MessageBox]::Show($m, $t, [System.Windows.Forms.MessageBoxButtons]::OKCancel)

        return ($r -eq [System.Windows.Forms.DialogResult]::OK)
    }

    static [bool] ShowConfirm([string]$m, [string]$t, [System.Windows.Forms.MessageBoxIcon]$i) {
        $r = [System.Windows.Forms.MessageBox]::Show($m, $t, [System.Windows.Forms.MessageBoxButtons]::OKCancel, $i)

        return ($r -eq [System.Windows.Forms.DialogResult]::OK)
    }

    static [string] ShowInput([string]$m, [string]$t) {
        return ([Microsoft.VisualBasic.Interaction]::InputBox($m, $t))
    }

    static [string] ShowInput([string]$m, [string]$t, [string]$d) {
        return ([Microsoft.VisualBasic.Interaction]::InputBox($m, $t, $d))
    }
}