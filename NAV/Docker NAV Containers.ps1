#Docker NAV containers

#https://hub.docker.com/r/microsoft/dynamics-nav
#docker pull microsoft/dynamics-nav:[version[-cu][-country]]
    #Version currently is 2016, 2017 or 2018 (omit to get newest)
    #cu is rtm, cu1, cu2, cu3,... (omit to get newest)
    #country is dk, de, fr, gb, na,... (omit to get w1)

#https://hub.docker.com/_/microsoft-businesscentral-onprem
#docker pull mcr.microsoft.com/businesscentral/onprem:[cu or build][-country][-platform]]
    #cu is rtm, cu1, cu2, cu3,... (omit to get newest)
    #build is a build number (omit to get newest)
    #country is one of the supported countries (listed below) (omit to get w1)
    #platform is one of the supported platforms (listed below) (omit to get ltsc2016)


#https://hub.docker.com/_/microsoft-businesscentral-sandbox
#docker pull mcr.microsoft.com/businesscentral/sandbox:[build][-country][-platform]]
    #build is a buid number (omit to get newest)
    #country is one of the supported countries (listed below) (omit to get w1)
    #platform is one of the supported platforms (listed below) (omit to get ltsc2016)

#Docker commands
#docker images
#docker image rm <image id>

#Install-Module -Name navcontainerhelper #Check for new releases here https://www.powershellgallery.com/packages/navcontainerhelper. See current version with Get-Module navcontainerhelper
#Write-NavContainerHelperWelcomeText #See all commands of NAVcontainer helper
#New-NavContainer -accept_eula -containerName my -imageName mcr.microsoft.com/businesscentral/onprem:14.8.38658.0-gb -includeAL -includeCSide #Download image and start container. If image already saved, starts a container.
#Get-NavContainers -includelabels
#Start-NavContainer <ContainerName> or Start-BCContainer <ContainerName>
#Stop-NavContainer <ContainerName> or Stop-BCContainer <ContainerName>
#Get-BCContainerNavVersion <ContainerName>
#Get-BCContainers -includeLabels
Get-BCContainerIpAddress BC153

#New-NavContainerWindowsUser -containerName Nav2016 -Credential Dimitrios
#New-NavContainerNavUser -containerName Nav2016 -Credential Dimitrios

#Get-NavContainerServerConfiguration Nav2016

#Look here for Container files
#C:\ProgramData\NavContainerHelper\Extensions


#Other resources
#https://blogs.msdn.microsoft.com/freddyk/


#Create NAV container -
#New-NavContainer -accept_eula -containerName Nav2016 -imageName microsoft/dynamics-nav:2016-gb -licenseFile "C:\Users\Dimitrios\OneDrive - The NAV People\NAV Licences\TNP Dev NAV 2018 041119.flf" -accept_outdated -includeCSide -shortcuts DesktopFolder

Import-NavContainerLicense BC153 -licenseFile "C:\Users\Dimitrios\OneDrive - The NAV People\NAV Licences\5393987 TNP BC Dev Feb20.flf"

#Create Latest BC gb -
#https://freddysblog.com/2019/07/31/preview-of-dynamics-365-business-central-2019-release-wave-2/?blogsub=confirming#subscribe-blog
$imageName = "mcr.microsoft.com/businesscentral/onprem:15.3.40074.40822-gb-ltsc2019"
$containerName = "BC153"
$auth = "Windows"
$credential = "Dimitrios" #New-Object pscredential 'admin', (ConvertTo-SecureString -String 'P@ssword1' -AsPlainText -Force)
$licenseFile = "C:\Users\Dimitrios\OneDrive - The NAV People\NAV Licences\5393987 TNP BC Dev Feb20.flf"

New-BCContainer -accept_eula `
                -imageName $imageName `
                -containerName $containerName `
                -auth $auth `
                -credential $credential `
                -licenseFile $licenseFile `
                -updateHosts `
                -includeAL
#Create Latest BC gb +