## dashboard.ps1
The aspire dashboard is probably the easiest way to surface OpenTelemetry data (logs, traces, metrics) in dev environments. It is published as a docker image. When you run an aspire orchestration locally, the dashboard is ***not*** run via docker but executed directly from a nuget package which contains the dashboard executable (on x64 Windows: Aspire.Dashboard.Sdk.win-x64). These packages are published per runtime identifier (the x64 Windows aspire dashboard is a separate nuget from the arm64 OSX package).

An additional advantage of using the nuget over the docker image is that the docker image is usually published later than the nuget (in case of the current version 9.1.0, the docker image was published weeks later).

This script runs the current (published) version of the aspire dashboard. The dashboard lives in the nuget package Aspire.Dashboard.Sdk.&lt;rid&gt;. *rid* is the runtime identifier of the form *win-x64*, *osx-arm64* ...

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
    

