#https://freddysblog.com/2020/08/11/bccontainerhelper/

install-module BCContainerHelper -force

#Write-BCContainerHelperWelcomeText

$artifactUrl = Get-BcArtifactUrl -type sandbox -country us -select Latest
New-BCContainer -accept_eula -containerName mysandbox -artifactUrl $artifactUrl