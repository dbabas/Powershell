#Run this from RTC folder
#finsql.exe Command=generatesymbolreference, Database=Live, ServerName=DomosnavBC\SQLEXPRESS

#If this doesn't work, create a shortcut of finsql.exe and change the command in the properties as follows:
#"C:\Program Files (x86)\Microsoft Dynamics 365 Business Central\140\RoleTailored Client\finsql.exe" generatesymbolreference=yes
#The dev environment will then create symbols each time you compile an object for this specific object.