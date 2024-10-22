cd "C:\Users\dimitrios.bampas\Documents\BC"
import-module .\New-SelfSignedCertificateEx.ps1
New-SelfSignedCertificateEx -Subject "CN=domosnavbc.northeurope.cloudapp.azure.com" -SAN "52.178.214.64" -IsCA $true -Exportable -StoreLocation LocalMachine