#Get-Service -Name MicrosoftDynamicsNAVServer*Arran* | where {$_.Name -notlike '*Con'} | Format-Table -AutoSize
#Get-Service -Name MicrosoftDynamicsNAVServer*Arran* | where {$_.Name -notlike '*Con'} | Set-Service -StartupType Disabled

#Get-NAVServerInstance | Format-Table -AutoSize


Get-Service -ComputerName mila-svr-navfe1 -Name MicrosoftDynamicsNAVServer*ArranIsle0* | Set-Service -StartupType manual
Get-Service -ComputerName mila-svr-navfe1 -Name MicrosoftDynamicsNAVServer*ArranIsle0* | Start-Service
#Get-Service -ComputerName mila-svr-navfe1 -Name MicrosoftDynamicsNAVServer*ArranIsle0* | Stop-Service
Get-Service -ComputerName mila-svr-navfe1 -Name MicrosoftDynamicsNAVServer*ArranIsle0* | Format-Table -AutoSize

Get-Service -ComputerName mila-svr-navfe2 -Name MicrosoftDynamicsNAVServer*WindowWare0* | Set-Service -StartupType manual
Get-Service -ComputerName mila-svr-navfe2 -Name MicrosoftDynamicsNAVServer*WindowWare0* | Start-Service
#Get-Service -ComputerName mila-svr-navfe2 -Name MicrosoftDynamicsNAVServer*WindowWare0* | Stop-Service
Get-Service -ComputerName mila-svr-navfe2 -Name MicrosoftDynamicsNAVServer*WindowWare0* | Format-Table -AutoSize