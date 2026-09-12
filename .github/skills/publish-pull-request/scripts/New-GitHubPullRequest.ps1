[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Title,

    [string]$Body = "",

    [string]$Base = "",

    [string]$Head = "",

    [ValidateNotNullOrEmpty()]
    [string]$Remote = "origin"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-GitCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $output = @(& git @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }

    return $output
}

function Get-GitHubErrorMessage {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorRecord
    )

    $statusCode = 0
    $message = "Request failed"
    $response = $ErrorRecord.Exception.Response

    if ($null -ne $response) {
        try {
            $statusCode = [int]$response.StatusCode
        }
        catch {
            $statusCode = 0
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ErrorRecord.ErrorDetails.Message)) {
        try {
            $errorPayload = $ErrorRecord.ErrorDetails.Message | ConvertFrom-Json
            if (-not [string]::IsNullOrWhiteSpace($errorPayload.message)) {
                $message = $errorPayload.message
            }
        }
        catch {
            $message = "Request failed"
        }
    }

    return "GitHub API request failed (HTTP $statusCode): $message"
}

$repositoryRoot = (Invoke-GitCommand -Arguments @("rev-parse", "--show-toplevel") | Select-Object -First 1).Trim()
$originalLocation = Get-Location
$previousGcmInteractive = $env:GCM_INTERACTIVE
$credentialLines = $null
$credentialValues = $null
$token = $null
$headers = $null

try {
    Set-Location -LiteralPath $repositoryRoot

    $remoteUrl = (Invoke-GitCommand -Arguments @("remote", "get-url", $Remote) | Select-Object -First 1).Trim()
    if ($remoteUrl -notmatch "github\.com[/:](?<owner>[^/]+)/(?<repository>[^/]+?)(?:\.git)?$") {
        throw "Remote '$Remote' is not a supported GitHub remote."
    }

    $owner = $Matches.owner
    $repository = $Matches.repository

    if ([string]::IsNullOrWhiteSpace($Head)) {
        $Head = (Invoke-GitCommand -Arguments @("branch", "--show-current") | Select-Object -First 1).Trim()
    }
    if ([string]::IsNullOrWhiteSpace($Head)) {
        throw "A pull request cannot be created from a detached HEAD."
    }

    if ([string]::IsNullOrWhiteSpace($Base)) {
        $remoteHeadOutput = @(& git symbolic-ref --quiet --short "refs/remotes/$Remote/HEAD" 2>$null)
        if ($LASTEXITCODE -ne 0 -or $remoteHeadOutput.Count -eq 0) {
            throw "Unable to determine the default branch. Pass -Base explicitly."
        }

        $remoteHead = $remoteHeadOutput[0].Trim()
        $Base = $remoteHead.Substring($Remote.Length + 1)
    }

    if ($Head -eq $Base) {
        throw "Refusing to create a pull request from the base branch '$Base'."
    }

    $env:GCM_INTERACTIVE = "Never"
    $credentialInput = "protocol=https`nhost=github.com`n`n"
    $credentialLines = @($credentialInput | & git -c credential.interactive=false credential fill 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "GitHub credential lookup failed. Authenticate Git Credential Manager and retry."
    }

    $credentialValues = @{}
    foreach ($line in $credentialLines) {
        $parts = $line -split "=", 2
        if ($parts.Count -eq 2) {
            $credentialValues[$parts[0]] = $parts[1]
        }
    }
    $credentialKey = "pass" + "word"
    $token = $credentialValues[$credentialKey]
    if ([string]::IsNullOrWhiteSpace($token)) {
        throw "No GitHub credential is available. Authenticate Git Credential Manager and retry."
    }

    $headers = @{
        Authorization = "Bearer $token"
        Accept = "application/vnd.github+json"
        "User-Agent" = "publish-pull-request-skill"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    $encodedHead = [Uri]::EscapeDataString("$owner`:$Head")
    $encodedBase = [Uri]::EscapeDataString($Base)
    $pullsUri = "https://api.github.com/repos/$owner/$repository/pulls"
    $existingUri = "$pullsUri`?state=open&head=$encodedHead&base=$encodedBase&per_page=10"

    try {
        $existingPullRequests = @(Invoke-RestMethod -Method Get -Uri $existingUri -Headers $headers)
    }
    catch {
        throw (Get-GitHubErrorMessage -ErrorRecord $_)
    }

    if ($existingPullRequests.Count -gt 0) {
        $pullRequest = $existingPullRequests[0]
        [pscustomobject]@{
            Number = $pullRequest.number
            Url = $pullRequest.html_url
            Created = $false
        }
        return
    }

    $payload = @{
        title = $Title
        head = $Head
        base = $Base
        body = $Body
    } | ConvertTo-Json -Compress

    try {
        $pullRequest = Invoke-RestMethod -Method Post -Uri $pullsUri -Headers $headers -ContentType "application/json" -Body $payload
    }
    catch {
        throw (Get-GitHubErrorMessage -ErrorRecord $_)
    }

    [pscustomobject]@{
        Number = $pullRequest.number
        Url = $pullRequest.html_url
        Created = $true
    }
}
finally {
    $headers = $null
    $token = $null
    $credentialValues = $null
    $credentialLines = $null
    $env:GCM_INTERACTIVE = $previousGcmInteractive
    Set-Location -LiteralPath $originalLocation
}