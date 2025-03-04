function Get-ImageIndexFromWim {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        $wimPath
    )
    try {
        Write-Host "Getting windows images from $wimPath..." -ForegroundColor Cyan
        $images = Get-WindowsImage -ImagePath $wimPath
        Write-Host 'Select an Image from the below available options:' -ForegroundColor Cyan
        $images | Select-Object ImageIndex, ImageName | Format-Table | Out-String | ForEach-Object { Write-Host $_ -ForegroundColor Cyan }
        $rh = Read-Host "Select Image Index ($($images[0].ImageIndex) - $($images[-1].ImageIndex))"
        while ($rh -notin $images.ImageIndex) {
            $rh = Read-Host "Select Image Index ($($images[0].ImageIndex) - $($images[-1].ImageIndex))"
        }
        Write-Host "Image $rh / $(($images | Where-Object {$_.ImageIndex -eq $rh}).ImageName) selected `n" -ForegroundColor Green
        return ($images | Where-Object { $_.ImageIndex -eq $rh }).ImageIndex
    } catch {
        Write-Warning $_.Exception.Message
    }
}
