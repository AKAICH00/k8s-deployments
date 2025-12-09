# PowerShell script to create a desktop shortcut for Infrastructure Management
# Run this once from PowerShell to create the shortcut

$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Infrastructure Manager.lnk")
$Shortcut.TargetPath = "wsl.exe"
$Shortcut.Arguments = "-e bash -c `"source /tmp/k8s-deployments/infra.sh; exec bash`""
$Shortcut.WorkingDirectory = "%USERPROFILE%"
$Shortcut.IconLocation = "C:\Windows\System32\cmd.exe,0"
$Shortcut.Description = "Launch Infrastructure Management Environment"
$Shortcut.Save()

Write-Host "Desktop shortcut created: Infrastructure Manager.lnk" -ForegroundColor Green
Write-Host ""
Write-Host "Double-click it to:" -ForegroundColor Cyan
Write-Host "  1. Open WSL terminal"
Write-Host "  2. Set KUBECONFIG automatically"
Write-Host "  3. CD to /tmp/k8s-deployments"
Write-Host "  4. Show infrastructure status"
Write-Host ""
Write-Host "Then run 'claude' to start Claude Code with full context!"
