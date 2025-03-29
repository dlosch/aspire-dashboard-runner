## dashboard.ps1
Runs the current (published) version of the aspire dashboard. The dashboard lives in the nuget package Aspire.Dashboard.Sdk.&lt;rid&gt;. *rid* is the runtime identifier of the form *win-x64*, *osx-arm64* ...

Script
- retrieves the local *rid*
- retrieves the most recent version number of this nuget package
- checks the local system nuget package folder if that nuget package and the version exists. If it exists, it will execute the dashboard from the tools directory of this nuget package
- if the package is not found, it donwloads and extracts the nuget to a local folder relative to the script (package is not installed in the system wide nuget packages folder).
- sets environment variables for the dashboard:
    ```
    $env:ASPNETCORE_URLS = "http://+:18889"
    $env:DOTNET_DASHBOARD_OTLP_ENDPOINT_URL = "http://+:4317"
    $env:DOTNET_DASHBOARD_OTLP_HTTP_ENDPOINT_URL = "http://+:18888"
    $env:DOTNET_DASHBOARD_UNSECURED_ALLOW_ANONYMOUS = "True"
    ```
    

