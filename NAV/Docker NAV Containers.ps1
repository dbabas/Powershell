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

#Install-Module -Name navcontainerhelper
#Write-NavContainerHelperWelcomeText #See all commands of NAVcontainer helper
#New-NavContainer -accept_eula -containerName my -imageName mcr.microsoft.com/businesscentral/onprem:14.8.38658.0-gb -includeAL -includeCSide #Download image and start container. If image already saved, starts a container.
#Get-NavContainers
#Start-NavContainer <ContainerName> or Start-BCContainer <ContainerName>
#Stop-NavContainer <ContainerName> or Stop-BCContainer <ContainerName>
#Get-BCContainerNavVersion <ContainerName>
#Get-BCContainers -includeLabels


#Other resources
#https://blogs.msdn.microsoft.com/freddyk/