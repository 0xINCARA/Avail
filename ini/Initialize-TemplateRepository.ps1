# NOTE: it is not recommended to change ANY of the Parameters, but area avilable.

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [String]$TemplateProjectName = "template-ubuntu",
    [String]$ConfigIniFileName = "config.ini.json",
    [String]$ConfigMetaFileName = "config.meta.json"
)


# defining config
$RootPath = (Get-Item $PSScriptRoot).Parent.FullName
$ConfigPath = (Get-ChildItem $RootPath -Recurse -Filter "config").FullName

$ConfigFile = (Get-ChildItem $ConfigPath -Recurse -Filter "*$ConfigIniFileName").FullName
$MetaFile = (Get-ChildItem $ConfigPath -Recurse -Filter "*$ConfigMetaFileName").FullName

$Config = Get-Content $ConfigFile | ConvertFrom-Json
$Meta = Get-Content $MetaFile | ConvertFrom-Json

$ProjectName = (Get-Item $RootPath).Name
$ReadmeFile = (Get-ChildItem $RootPath -Filter "*README.md").FullName
$CiFile = (Get-ChildItem $RootPath -Recurse -Filter "*ci.yml").FullName

function ReplaceContents {
    # places contents in a given file
    param (
        [String]$JobName,
        [String]$FilePath,
        [String]$OldText,
        [String]$NewText
    )
    
    $Contents = Get-Content -Path $FilePath
    $UpdatedContents = $Contents -Replace $OldText,$NewText
    Set-Content -Path $FilePath -Value $UpdatedContents
    Write-Output "Replace-Content  [$JobName] : Updated $FilePath"
}

# replace README logo
ReplaceContents -JobName "ProjectLogoPath" `
    -FilePath $ReadmeFile `
    -OldText $Meta.ProjectLogoPath `
    -NewText $Config.ProjectLogoPath

# replace README tagline
ReplaceContents -JobName "ProjectTagline" `
    -FilePath $ReadmeFile `
    -OldText $Meta.ProjectTagline `
    -NewText $Config.ProjectTagline 


# replace stackshare account
$StackSharePrefix = "https://stackshare.io/"

ReplaceContents -JobName "StackShareAccount" `
    -FilePath $ReadmeFile `
    -OldText ("{0}{1}" -f $StackSharePrefix, $Meta.StackShareAccount) `
    -NewText ("{0}{1}" -f $StackSharePrefix, $Config.StackShareAccount)


# replace codecov account
$CodeCovSharePrefix = "https://codecov.io/gh/"

ReplaceContents -JobName "CodeCovAccount" `
    -FilePath $ReadmeFile `
    -OldText ("{0}{1}" -f $CodeCovSharePrefix, $Meta.CodeCovAccount) `
    -NewText ("{0}{1}" -f $CodeCovSharePrefix, $Config.CodeCovAccount)

# replace github account
ReplaceContents -JobName "GitHubAccount" `
    -FilePath $ReadmeFile `
    -OldText ("{0}/{1}" -f $Meta.GitHubAccount, $ProjectName) `
    -NewText ("{0}/{1}" -f $Config.GitHubAccount, $ProjectName)

# replace dockerhub account
ReplaceContents -JobName "DockerHubAccount" `
    -FilePath $CiFile `
    -OldText $Meta.DockerHubAccount `
    -NewText $Config.DockerHubAccount

# replace ProjectName everywhere except in ini directory
$TemplateFiles = (Get-ChildItem $RootPath -Exclude "ini") | Get-ChildItem -File -Recurse

foreach ($File in $TemplateFiles) {
    ReplaceContents -JobName "ProjectName" `
        -FilePath $File.FullName `
        -OldText $TemplateProjectName `
        -NewText $ProjectName
}

# Replacing config.meta for next interation
$Config | ConvertTo-Json  | Set-Content $MetaFile
Write-Output "New Metadata Saved to $MetaFile"
