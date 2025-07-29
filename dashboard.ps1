#-------------------------------------------------------------
# Aspire Dashboard Runner
# This script downloads and runs the Aspire Dashboard for the 
# current platform's runtime identifier (RID).
#-------------------------------------------------------------

#
# 1. Get the current runtime identifier (RID)
#
$dotnetInfo = dotnet --info
$ridLine = $dotnetInfo | Where-Object { $_ -match 'RID:' }
$rid = $ridLine -replace 'RID:\s+', ''
$rid = $rid.Trim()
$nugetPackageName = "Aspire.Dashboard.Sdk.$rid".tolower()

#
# 2. Helper function to determine latest package version
#
function Get-LatestNuGetPackageVersion {
    param (
        [string]$PackageName
    )
    
    # should technically be tolower!?
    $indexUrl = "https://api.nuget.org/v3-flatcontainer/$PackageName/index.json"
    try {
        $response = Invoke-RestMethod -Uri $indexUrl -Method Get
        if ($response.versions -and $response.versions.Count -gt 0) {
            return $response.versions[-1]  # Return the latest version TODO check for prerelease
        }
    }
    catch {
        Write-Error "Failed to get latest version for package $PackageName. Error: $_"
    }
    
    return $null
}

#
# 3. Determine package version to use
#
$nugetVersion = Get-LatestNuGetPackageVersion -PackageName $nugetPackageName
if (-not $nugetVersion) {
    Write-Warning "Could not determine latest version for $nugetPackageName. Using default version."
    $nugetVersion = "9.1.0"  # Fallback version
}
Write-Host "Using package: $nugetPackageName version: $nugetVersion"

#
# 4. Prepare directory structure
#
$baseOutputDir = "./dashboard"
$versionedOutputDir = "$baseOutputDir/$rid/$nugetVersion"
$dashboardExeDir = "$versionedOutputDir/tools"

# Determine executable extension based on platform
if ($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and [Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)) {
    $exeExtension = ".exe"
} else {
    $exeExtension = ""
}

$dashboardExeDir = "$versionedOutputDir/tools"
$dashboardExePath = "./Aspire.Dashboard$exeExtension"

#
# 5. Download and extract package if needed
#
# Resolve the NuGet package directory
if ($env:NUGET_PACKAGES) {
    # Use the NUGET_PACKAGES environment variable if set
    $nugetGlobalPackagesDir = $env:NUGET_PACKAGES
} else {
    # Default to the user's global NuGet packages directory
    if ($IsWindows) {
        $nugetGlobalPackagesDir = Join-Path -Path ([System.Environment]::GetFolderPath("UserProfile")) -ChildPath ".nuget\packages"
    } else {
        $nugetGlobalPackagesDir = "~/.nuget/packages"
    }
}

# Construct the path to the package in the NuGet directory
$systemPackagePath = Join-Path -Path $nugetGlobalPackagesDir -ChildPath "$nugetPackageName/$nugetVersion"

if (Test-Path $systemPackagePath) {
    Write-Host "Package $nugetPackageName version $nugetVersion found in NuGet directory ($nugetGlobalPackagesDir). Skipping download." -ForegroundColor Green

    $dashboardExeDir = Join-Path -Path $systemPackagePath -ChildPath "tools"

} elseif (Test-Path $dashboardExeDir) {
    Write-Host "Version $nugetVersion already downloaded. Skipping download." -ForegroundColor Green
} else {
    # Create base directory if needed
    if (-not (Test-Path $baseOutputDir)) {
        New-Item -ItemType Directory -Path $baseOutputDir -Force | Out-Null
    }
    Write-Host "Downloading version $nugetVersion..." -ForegroundColor Yellow
    
    # Create versioned directory
    if (-not (Test-Path $versionedOutputDir)) {
        New-Item -ItemType Directory -Path $versionedOutputDir -Force | Out-Null
    }
    
    # Download package
    $nugetUrl = "https://www.nuget.org/api/v2/package/$nugetPackageName/$nugetVersion"
    $zipPath = "$versionedOutputDir/package.zip"
    
    try {
        Invoke-WebRequest -Uri $nugetUrl -OutFile $zipPath
        
        # Extract and cleanup
        Expand-Archive -Path $zipPath -DestinationPath $versionedOutputDir -Force
        Remove-Item $zipPath
        
        Write-Host "Download and extraction completed." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download or extract package. Error: $_"
        exit 1
    }
}

#
# 6. Set environment variables for dashboard
#
$env:ASPNETCORE_URLS = "http://+:18889"
$env:DOTNET_DASHBOARD_OTLP_ENDPOINT_URL = "http://+:4317"
$env:DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL = "http://+:18888"
$env:DOTNET_DASHBOARD_UNSECURED_ALLOW_ANONYMOUS = "True"
#
# 7. Run the dashboard
#
Push-Location -Path $dashboardExeDir
try {
    if (Test-Path $dashboardExePath) {
        if (!($IsWindows -or ($PSVersionTable.PSVersion.Major -lt 6 -and [Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT))) {
            # Make the executable runnable on non-Windows platforms
            chmod +x $dashboardExePath
        }

        & $dashboardExePath
    } 
    else {
        Write-Error "Could not find Aspire Dashboard executable at path: $dashboardExePath"
        exit 1
    }
} 
finally {
# Restore the original directory
    Pop-Location
}
