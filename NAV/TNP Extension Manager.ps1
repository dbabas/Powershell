[string]  $ServerInstance      = 'Brigade140DEV'
[string]  $ServerTenant        = 'default'
[boolean] $MultiTenantServer   = $false
[string]  $ExtensionPublishers = 'The 365 People,The NAV People,Default publisher'
[string]  $ExtensionScope      = 'Tenant'
[boolean] $MultiSelectMode     = $false
[boolean] $AdvancedMode        = $false
[boolean] $DebugMode           = $false

[string]  $Author              = 'The 365 People'
[string]  $Name                = 'Extension Manager'
[string]  $Version             = '6.1.0'
[string]  $Date                = 'May 2019'
[string]  $Website             = 'https://www.the365people.com'

[Script] $Script = [Script]::new( `
    [Arguments]::new($ServerInstance, $ServerTenant, $MultiTenantServer, $ExtensionPublishers, $ExtensionScope, $MultiSelectMode, $AdvancedMode, $DebugMode), `
    [ScriptInfo]::new($Author, $Name, $Version, $Date, $Website) `
)
$Script.Run()

enum Command { Empty; Exit; Reload; Select; SelectAll; SelectPublished; SelectNonPublished; SelectInstalled; SelectNonInstalled; ClearSelection; 
    ToggleScope; ToggleMultiSelectMode; ToggleAdvancedMode; Help; ShowInformation; Publish; Synchronise; Upgrade; Install; 
    Uninstall; Remove; Unpublish; ForceUnpublish }
enum MenuItemType { Item; NewLine; Separator }
enum Result { Empty; Success; Confirmation; Failure; Warning }

class Arguments {
    [string] $ServerInstance = ''
    [string] $ServerTenant = ''
    [boolean] $MultiTenantServer = $false
    [System.Collections.ArrayList] $ExtensionPublishers = @()
    [string] $ExtensionScope = ''
    [boolean] $MultiSelectMode = $false
    [boolean] $AdvancedMode = $false
    [string] $FolderPath = ''
    [boolean] $DebugMode = $false

    Arguments() {
    }

    Arguments([string] $pServerInstance, [string] $pServerTenant, [boolean] $pMultiTenantServer, [string] $pExtensionPublishers, [string] $pExtensionScope, `
        [boolean] $pMultiSelectMode, [boolean] $pAdvancedMode, [boolean] $pDebugMode) {
        $this.ServerInstance = $pServerInstance
        $this.ServerTenant = $pServerTenant
        $this.MultiTenantServer = $pMultiTenantServer
        $this.ExtensionPublishers = $pExtensionPublishers.Split(',;|')
        $this.ExtensionScope = $pExtensionScope
        $this.MultiSelectMode = $pMultiSelectMode
        $this.AdvancedMode = $pAdvancedMode
        $this.FolderPath = $this.FindFolderPath()
        $this.DebugMode = $pDebugMode
    }

    [System.Collections.ArrayList] GetProperties() {
        [System.Collections.ArrayList] $Properties = @()
        [Converter] $Converter = [Converter]::new()
        $Properties.Add([Property]::new('Server Instance', $this.ServerInstance))
        $Properties.Add([Property]::new('Server Tenant', $this.ServerTenant))
        $Properties.Add([Property]::new('Extension Publishers', $Converter.FormatArrayList($this.ExtensionPublishers)))
        $Properties.Add([Property]::new('Folder Path', $this.FolderPath))
        $Properties.Add([Property]::new('Multi-Tenant Server', $Converter.FormatBoolean($this.MultiTenantServer)))
        $Properties.Add([Property]::new('Extension Scope', $this.ExtensionScope))
        $Properties.Add([Property]::new('Multi-Select Mode', $Converter.FormatBoolean($this.MultiSelectMode)))
        $Properties.Add([Property]::new('Advanced Mode', $Converter.FormatBoolean($this.AdvancedMode)))
        return $Properties
    }
    
    hidden [string] FindFolderPath() {
        [Path] $Path = [Path]::new()
        return $Path.GetFolder($MyInvocation.PSCommandPath)
    }
}

class ScriptInfo {
    [string] $Author = ''
    [string] $Name = ''
    [string] $Version = ''
    [string] $Date = ''
    [string] $Website = ''

    ScriptInfo([string] $pAuthor, [string] $pName, [string] $pVersion, [string] $pDate, [string] $pWebsite) {
        $this.Author = $pAuthor
        $this.Name = $pName
        $this.Version = $pVersion
        $this.Date = $pDate
        $this.Website = $pWebsite
    }
}

class Script {
    [ScriptInfo] $ScriptInfo = $null
    [BCManager] $BCManager = $null
    [boolean] $Running = $false
    [Menu] $Menu = $null
    [CommandInfo] $CommandInfo = $null
    [boolean] $ShowAcknowledgement = $false

    Script([Arguments] $pArguments, [ScriptInfo] $pScriptInfo) { 
        $this.BCManager = [BCManager]::new($pArguments)
        $this.ScriptInfo = $pScriptInfo
    }
    
    [void] Run() {
        $this.Running = $true
        $this.DrawTitle($true)
        $this.ReloadOnStart()
        do {
            $this.DrawTitle($false)
            $this.DrawExtensions()
            $this.DrawMenu()
            $this.DrawSelectionPrompt()
            $this.HandleCommand()
        } while ($this.Running)
        $this.DrawGoodBye()
    }

    hidden [void] DrawTitle([boolean] $pNewLineAfter) {
        [string] $Title = -join($this.ScriptInfo.Author, ' - ', $this.ScriptInfo.Name, ' - ', $this.ScriptInfo.Version, `
            ' - ', $this.ScriptInfo.Date, ' - ', $this.ScriptInfo.Website)
        [Table] $TitleTable = [Table]::new($Title, 'Gray', @(
            [TableColumn]::new('', 21), 
            [TableColumn]::new('', 66, 'Yellow'), `
            [TableColumn]::new('', 21), 
            [TableColumn]::new('', 8, 'Yellow')
        ))
        Clear-Host
        $TitleTable.DrawHeader()
        [PropertyColumniser] $PropertyColumniser = [PropertyColumniser]::new($this.BCManager.Arguments.GetProperties(), 2)
        [System.Collections.ArrayList] $Row = $null
        foreach ($Row in $PropertyColumniser.Rows) { 
            $TitleTable.DrawRow($Row) 
        }
        $TitleTable.DrawFooter()
        if ($pNewLineAfter) {
            Write-Host
        }
    }

    hidden [void] ReloadOnStart() {
        $this.BCManager.Reload()
        $this.HandleResult($this.BCManager.Result)
    }

    hidden [void] DrawMenu() {
        $this.Menu = [Menu]::new(120) 
        $this.BuildExtensionMenus()
        $this.BuildMainMenu()
        $this.Menu.Draw()
    }

    hidden [void] BuildExtensionMenus() {
        if ($this.BCManager.IsAnyExtensionSelected()) {
            $this.Menu.AddItems(@(
                [MenuItem]::new('f', 'Information', 'Shows first selected extension information', [Command]::ShowInformation),
                [MenuItem]::new('p', 'Publish', 'Publishes selected extensions', [Command]::Publish),
                [MenuItem]::new('i', 'Install', 'Installs selected extensions', [Command]::Install),
                [MenuItem]::new('n', 'Uninstall', 'Uninstalls selected extensions', [Command]::Uninstall),
                [MenuItem]::new('u', 'Un-publish', 'Un-publishes selected extensions', [Command]::Unpublish),
                [MenuItem]::new([MenuItemType]::NewLine, $this.BCManager.Arguments.AdvancedMode),
                [MenuItem]::new('fu', 'Force Un-publish', 'Force un-publishes selected extensions', [Command]::ForceUnpublish, $this.BCManager.Arguments.AdvancedMode),
                [MenuItem]::new('s', 'Synchronise', 'Synchronises selected extensions', [Command]::Synchronise, $this.BCManager.Arguments.AdvancedMode),
                [MenuItem]::new('d', 'Upgrade', 'Upgrades data of all selected extensions', [Command]::Upgrade, $this.BCManager.Arguments.AdvancedMode),
                [MenuItem]::new('r', 'Remove', 'Removes extension: uninstalls, un-publishes and removes all saved data', [Command]::Remove, $this.BCManager.Arguments.AdvancedMode)
            ))
            $this.Menu.Items.Add([MenuItem]::new([MenuItemType]::Separator))
        }
    }

    hidden [void] BuildMainMenu() {
        $this.Menu.AddItems(@(
            [MenuItem]::new('x', 'Exit', 'Exits the script', [Command]::Exit),
            [MenuItem]::new('e', 'Reload', 'Reloads all extensions', [Command]::Reload),
            [MenuItem]::new('o', 'Toggle Scope', 'Toggles scope between "Global" and "Tenant"', [Command]::ToggleScope)
            [MenuItem]::new('m', 'Toggle Multi-Select Mode', 'Toggles multi-selection mode', [Command]::ToggleMultiSelectMode)
            [MenuItem]::new('v', 'Toggle Advanced Mode', 'Toggles advanced mode', [Command]::ToggleAdvancedMode),
            [MenuItem]::new([MenuItemType]::NewLine, $this.BCManager.Arguments.MultiSelectMode),
            [MenuItem]::new('a', 'Sel. All', 'Selects all extensions', [Command]::SelectAll, $this.BCManager.Arguments.MultiSelectMode),
            [MenuItem]::new('p+', 'Sel. Published', 'Selects published extensions', [Command]::SelectPublished, $this.BCManager.Arguments.MultiSelectMode),
            [MenuItem]::new('p-', 'Sel. Non-Published', 'Selects non-published extensions', [Command]::SelectNonPublished, $this.BCManager.Arguments.MultiSelectMode),
            [MenuItem]::new('i+', 'Sel. Installed', 'Selects installed extensions', [Command]::SelectInstalled, $this.BCManager.Arguments.MultiSelectMode),
            [MenuItem]::new('i-', 'Sel. Non-Installed', 'Selects not-installed extensions', [Command]::SelectNonInstalled, $this.BCManager.Arguments.MultiSelectMode),
            [MenuItem]::new('c', 'Clear Selection', 'Clears extensions selection', [Command]::ClearSelection)
        ))
    }

    hidden [void] DrawExtensions() {
        [Table] $Table = [Table]::new('', $(
            [TableColumn]::new('Sel', 4),
            [TableColumn]::new('Idx', 4, 'Cyan'),
            [TableColumn]::new('Name', 56),
            [TableColumn]::new('Version', 15),
            [TableColumn]::new('Scope', 8)
            [TableColumn]::new('Publ.', 6),
            [TableColumn]::new('Sync.', 6),
            [TableColumn]::new('Upgr.', 6),
            [TableColumn]::new('Inst.', 6),
            [TableColumn]::new('File', 5)
        ))
        $Table.DrawHeader()
        [ExtensionInfo] $Extension = $null
        [Converter] $Converter = [Converter]::new()
        foreach ($Extension in $this.BCManager.Extensions) {
            $Table.DrawRow(@($Converter.FormatBoolean($Extension.IsSelected), $Extension.Selector, $Extension.Name, $Extension.Version, $Extension.Scope, `
                $Converter.FormatAndPadBoolean($Extension.IsPublished, 3), $Converter.FormatAndPadBoolean($Extension.IsSynchronised, 3), 
                $Converter.FormatAndPadBoolean($Extension.IsUpgraded, 3), $Converter.FormatAndPadBoolean($Extension.IsInstalled, 3), 
                $Converter.FormatAndPadBoolean($Extension.FileExists, 3)), $Extension.IsSelected)
        }
        $Table.DrawFooter()
    }

    hidden [void] DrawSelectionPrompt() {
        Write-Host
        Write-Host 'Choose your option and press "Enter": ' -ForegroundColor Cyan -NoNewline
    }

    hidden [void] HandleCommand() {
        [string] $Selection = Read-Host
        [Result] $Result = [Result]::Success
        $this.ShowAcknowledgement = $false
        $this.DrawTitle($true)
        $this.DetectCommand($Selection)
        if ($null -ne $this.CommandInfo) {
            switch ($this.CommandInfo.Command) {
                Exit { 
                    $this.Running = $false
                }
                Reload { 
                    $this.BCManager.Reload() 
                    $Result = $this.BCManager.Result
                }
                Select { 
                    $this.BCManager.Select($this.CommandInfo.Extension)
                    $Result = $this.BCManager.Result
                }
                SelectAll {
                    $this.BCManager.SelectMultiple($this.CommandInfo)
                    $Result = $this.BCManager.Result
                }
                SelectPublished {
                    $this.BCManager.SelectMultiple($this.CommandInfo)
                    $Result = $this.BCManager.Result
                }
                SelectNonPublished {
                    $this.BCManager.SelectMultiple($this.CommandInfo)
                    $Result = $this.BCManager.Result
                }
                SelectInstalled {
                    $this.BCManager.SelectMultiple($this.CommandInfo)
                    $Result = $this.BCManager.Result
                }
                SelectNonInstalled {
                    $this.BCManager.SelectMultiple($this.CommandInfo)
                    $Result = $this.BCManager.Result
                }
                ClearSelection { 
                    $this.BCManager.SelectMultiple($this.CommandInfo)
                    $Result = $this.BCManager.Result
                }
                ToggleScope {
                    $this.BCManager.ToggleScope()
                    $Result = $this.BCManager.Result
                }
                ToggleMultiSelectMode {
                    $this.BCManager.ToggleMultiSelectMode()
                    $Result = $this.BCManager.Result
                }
                ToggleAdvancedMode {
                    $this.BCManager.ToggleAdvancedMode()
                    $Result = $this.BCManager.Result
                }
                ShowInformation { 
                    $this.BCManager.ShowInformation() 
                    $Result = $this.BCManager.Result
                }
                Publish { 
                    $this.BCManager.PublishMultiple() 
                    $Result = $this.BCManager.Result
                }
                Synchronise { 
                    $this.BCManager.SynchroniseMultiple() 
                    $Result = $this.BCManager.Result
                }
                Upgrade { 
                    $this.BCManager.UpgradeMultiple() 
                    $Result = $this.BCManager.Result
                }
                Install { 
                    $this.BCManager.InstallMultiple() 
                    $Result = $this.BCManager.Result
                }
                Uninstall { 
                    $this.BCManager.UninstallMultiple() 
                    $Result = $this.BCManager.Result
                }
                Unpublish { 
                    $this.BCManager.UnpublishMultiple($false) 
                    $Result = $this.BCManager.Result
                }
                ForceUnpublish { 
                    $this.BCManager.UnpublishMultiple($true) 
                    $Result = $this.BCManager.Result
                }
                Remove { 
                    $this.BCManager.Remove() 
                    $Result = $this.BCManager.Result
                }
                default { 
                    $Result = $this.HandleUnrecognisedSelection($Selection)
                }
            }
        } else { 
            $Result = $this.HandleUnrecognisedSelection($Selection)
        }
        $this.HandleResult($Result)
        Write-Host
    }

    hidden [void] DetectCommand([string] $pSelection) {
        $pSelection = $pSelection.ToLower().Trim()
        $this.CommandInfo = $null
        $this.DetectCommandFromMenu($pSelection, $this.Menu)
        $this.DetectCommandFromExtensions($pSelection)
    }

    hidden [void] DetectCommandFromMenu([string] $pSelection, [Menu] $pMenu) {
        if (($null -eq $this.CommandInfo) -and ($null -ne $pMenu)) {            
            [MenuItem] $MenuItem = $null
            foreach ($MenuItem in $pMenu.Items) {
                if (($MenuItem.Selector -eq $pSelection) -and ($MenuItem.IsActive)) {
                    $this.CommandInfo = [CommandInfo]::new($MenuItem.Command)
                    break
                }
            }
        }
    }

    hidden [void] DetectCommandFromExtensions([string] $pSelection) {
        if ($null -eq $this.CommandInfo) {
            [ExtensionInfo] $Extension = $null
            foreach ($Extension in $this.BCManager.Extensions) {
                if ($Extension.Selector -eq $pSelection) {
                    $this.CommandInfo = [CommandInfo]::new([Command]::Select, $Extension)
                    break
                }
            }
        }
    }

    hidden [Result] HandleUnrecognisedSelection($pSelection) {
        return [ResultToolkit]::ResultWithMessage([Result]::Warning, -Join('Unrecognised selection: ', $pSelection))
    }

    hidden [void] HandleResult([Result] $pResult) { 
        if (([ResultToolkit]::RequiresConfirmation($pResult)) -or ($this.BCManager.Arguments.DebugMode)) {
            $this.DrawPressEnter()
            Read-Host
        }
    }

    hidden [void] DrawPressEnter() {
        Write-Host
        Write-Host 'Press "Enter" to continue: ' -ForegroundColor Cyan -NoNewline
    }

    hidden [void] DrawGoodBye() {
        Write-Host 'Good bye!'
        Write-Host
    }
}

class CommandInfo {
    [Command] $Command = [Command]::Empty
    [ExtensionInfo] $Extension = $null
    [bool] $ShowAcknowledgement = $true

    CommandInfo() {
    }

    CommandInfo([Command] $pCommand) {
        $this.Command = $pCommand
    }

    CommandInfo([Command] $pCommand, [ExtensionInfo] $pExtension) {
        $this.Command = $pCommand
        $this.Extension = $pExtension
        $this.ShowAcknowledgement = $false
    }
}

class BCManager {
    [Arguments] $Arguments = [Arguments]::new()
    [System.Collections.ArrayList] $Extensions = @()
    [Result] $Result = [Result]::Empty

    BCManager([Arguments] $pArguments) {
        $this.Arguments = $pArguments
        $this.LoadModules()        
    }

    hidden [void] LoadModules() {
        [string] $ServicePath = $this.FindServicePath()
        Import-Module (-Join($ServicePath, '\', 'Microsoft.Dynamics.Nav.Apps.Management.dll')) -DisableNameChecking
    }

    hidden [string] FindServicePath() {
        [string] $ServicePath = ''
        [string] $RegistryKeysPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Dynamics NAV'
        [object] $RegistryKeys = Get-ChildItem -Path $RegistryKeysPath
        [Microsoft.Win32.RegistryKey] $RegistryKey = $null
        if ($RegistryKeys.GetType() -eq [Microsoft.Win32.RegistryKey]) {
            $RegistryKey = $RegistryKeys
        } else {
            if ($RegistryKeys.Count -gt 0) {
                $RegistryKey = $RegistryKeys[$RegistryKeys.Count - 1]
            } else {
                throw 'Can''t find Dynamics service folder location in registry.'
            }
        }
        [string] $ServiceRegistryKeyPath = -Join('Registry::', $RegistryKey.Name, '\Service')
        $ServicePath = Get-ItemPropertyValue -Path $ServiceRegistryKeyPath -Name 'Path'
        return $ServicePath
    }

    [void] Reload() {
        $this.Initialise('Detecting extensions')
        $this.Extensions = @()
        [System.Collections.ArrayList] $TemporaryExtensions = @()
        $this.FindServerExtensions($TemporaryExtensions)
        $this.FindFolderExtensions($TemporaryExtensions)        
        $this.SortAndIndexExtensions($TemporaryExtensions)
        $this.Finalise()
    }

    [void] Select([ExtensionInfo] $pExtension) {
        $this.Initialise()
        [boolean] $IsSelected = $pExtension.IsSelected
        if ( -not ($this.Arguments.MultiSelectMode)) {
            $this.ClearSelection()
        }
        $pExtension.IsSelected = ( -not ($IsSelected))
        $this.Finalise()
    }
    
    [void] SelectMultiple([CommandInfo] $pCommandInfo) {
        $this.Initialise()
        if ($this.Arguments.MultiSelectMode) {
            [ExtensionInfo] $Extension = $null
            foreach ($Extension in $this.Extensions) {
                switch ($pCommandInfo.Command) {
                    SelectAll {
                        $Extension.IsSelected = $true
                    }
                    SelectPublished {
                        $Extension.IsSelected = $Extension.IsPublished
                    }
                    SelectNonPublished {
                        $Extension.IsSelected = ( -not ($Extension.IsPublished))
                    }
                    SelectInstalled {
                        $Extension.IsSelected = $Extension.IsInstalled
                    }
                    SelectNonInstalled {
                        $Extension.IsSelected = ( -not ($Extension.IsInstalled))
                    }
                    ClearSelection { 
                        $Extension.IsSelected = $false
                    }
                }
            }
            $this.Finalise()
        } else {
            $this.Finalise([Result]::Failure, 'Multi-select mode hasn''t been activated')
        }
    }

    hidden [void] ClearSelection() {
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.Extensions) {
            $Extension.IsSelected = $false
        }
    }

    [void] ToggleScope() {
        $this.Initialise()
        if ($this.Arguments.ExtensionScope -eq 'Global') {
            $this.Arguments.ExtensionScope = 'Tenant'
        } else {
            $this.Arguments.ExtensionScope = 'Global'
        }
        $this.Finalise()
    }

    [void] ToggleMultiSelectMode() {
        $this.Initialise()
        $this.Arguments.MultiSelectMode = ( -not ($this.Arguments.MultiSelectMode))
        $this.ClearSelection()   
        $this.Finalise()
    }

    [void] ToggleAdvancedMode() {
        $this.Initialise()
        $this.Arguments.AdvancedMode = ( -not ($this.Arguments.AdvancedMode))
        $this.ClearSelection()   
        $this.Finalise()
    }

    [void] ShowInformation() {
        $this.Initialise()
        [System.Collections.ArrayList] $SelectedExtensions = $this.GetSelectedExtensions()
        if ($SelectedExtensions.Count -gt 0) {
            [ExtensionInfo] $SelectedExtension = $SelectedExtensions[0]
            $this.UpdateDependentExtensions($SelectedExtension)
            [Table] $Table = [Table]::new('Extension Information', @(
                [TableColumn]::new('', 25)
                [TableColumn]::new('', 91, 'Yellow')
            ))
            $Table.DrawHeader()
            [Property] $Property = $null
            foreach ($Property in $SelectedExtension.GetProperties()) { 
                $Table.DrawRow(@($Property.Name, $Property.Value)) 
            }
            $Table.DrawFooter()
            $this.Finalise([Result]::Confirmation, '')
        } else {
            $this.Finalise([Result]::Failure, 'No extension has been selected')
        }
    }

    [void] PublishMultiple() {
        $this.Initialise()
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.GetSelectedExtensions()) {
            $this.Publish($Extension)
        }
        $this.Finalise()
    }

    hidden [void] Publish([ExtensionInfo] $pExtension) {
        $this.InitialiseExtension($pExtension, 'Publishing')
        if ( -not ($pExtension.IsPublished)) {
            if (($pExtension.FileExists) -and ($pExtension.FilePath -ne '')) {
                $this.PublishSuperExtensions($pExtension)
                if ($this.Arguments.ExtensionScope -eq 'Tenant') {
                    Publish-NAVApp -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Path $pExtension.FilePath `
                        -Scope $this.Arguments.ExtensionScope -SkipVerification
                } else {
                    Publish-NAVApp -ServerInstance $this.Arguments.ServerInstance -Path $pExtension.FilePath -Scope $this.Arguments.ExtensionScope -SkipVerification
                }
                $this.UpdateExtensionStatus($pExtension)
                $this.FinaliseExtension($pExtension, $pExtension.IsPublished, 'Published', 'Publishing failed')
            } else {
                $this.FinaliseExtension($pExtension, [Result]::Failure, 'File can''t be located')
            }
        } else {
            $this.FinaliseExtension($pExtension, [Result]::Success, 'Published already')
        }
    }

    hidden [void] PublishSuperExtensions([ExtensionInfo] $pExtension) {
        [System.Collections.ArrayList] $SuperExtensions = $this.FindSuperExtensions($pExtension)
        [ExtensionInfo] $SuperExtension = $null
        foreach ($SuperExtension in $SuperExtensions) {
            if ( -not ($SuperExtension.IsPublished)) {
                $this.Publish($SuperExtension)
            }
        }
    }

    [void] SynchroniseMultiple() {
        $this.Initialise()
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.GetSelectedExtensions()) {
            $this.Synchronise($Extension)
        }
        $this.Finalise()
    }

    hidden [void] Synchronise([ExtensionInfo] $pExtension) {
        $this.InitialiseExtension($pExtension, 'Synchronising')
        if ( -not ($pExtension.IsSynchronised)) {
            if ( -not ($pExtension.IsPublished)) {
                $this.Publish($pExtension)
            }
            if ($pExtension.IsPublished) {
                Sync-NavApp -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $pExtension.Name -Version $pExtension.Version -PassThru
                $this.UpdateExtensionStatus($pExtension)
                $this.FinaliseExtension($pExtension, $null -ne $pExtension, 'Synchronised', 'Synchronisation failed')
            }
        } else {
            $this.FinaliseExtension($pExtension, [Result]::Success, 'Synchronised already')
        }
    }

    [void] UpgradeMultiple() {
        $this.Initialise()
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.GetSelectedExtensions()) {
            $this.Upgrade($Extension)
        }
        $this.Finalise()
    }

    hidden [void] Upgrade([ExtensionInfo] $pExtension) {
        $this.InitialiseExtension($pExtension, 'Upgrading')
        if ( -not ($pExtension.IsUpgraded)) {
            if ( -not ($pExtension.IsPublished)) {
                $this.Publish($pExtension)
            }
            if (($pExtension.IsPublished) -and ( -not ($pExtension.IsSynchronised))) {
                $this.Synchronise($pExtension)
            }
            if (($pExtension.IsPublished) -and ($pExtension.IsSynchronised)) {
                Start-NAVAppDataUpgrade -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $pExtension.Name -Version $pExtension.Version
                $this.UpdateExtensionAllVersionsStatus($pExtension)
                $this.FinaliseExtension($pExtension, $pExtension.IsInstalled, 'Upgraded', 'Upgrade failed')
            }
        } else {
            $this.FinaliseExtension($pExtension, [Result]::Success, 'Upgraded already')
        }
    }

    [void] InstallMultiple() {
        $this.Initialise()
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.GetSelectedExtensions()) {
            $this.Install($Extension)
        }
        $this.Finalise()
    }

    hidden [void] Install([ExtensionInfo] $pExtension) {
        $this.InitialiseExtension($pExtension, 'Installing')
        if ( -not ($pExtension.IsInstalled)) {
            $this.InstallSuperExtensions($pExtension)
            if ( -not ($pExtension.IsPublished)) {
                $this.Publish($pExtension)
            }
            if (($pExtension.IsPublished) -and ( -not ($pExtension.IsSynchronised))) {
                $this.Synchronise($pExtension)
            }
            if (($pExtension.IsPublished) -and ($pExtension.IsSynchronised) -and ( -not ($pExtension.IsUpgraded))) {
                $this.Upgrade($pExtension)
            }
            if (($pExtension.IsPublished) -and ($pExtension.IsSynchronised) -and ($pExtension.IsUpgraded) -and ( -not ($pExtension.IsInstalled))) {
                Install-NavApp -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $pExtension.Name -Version $pExtension.Version
                $this.UpdateExtensionStatus($pExtension)
                $this.FinaliseExtension($pExtension, $pExtension.IsInstalled, 'Installed', 'Installation failed')
            }
        } else {
            $this.FinaliseExtension($pExtension, [Result]::Success, 'Installed already')
        }
    }

    hidden [void] InstallSuperExtensions([ExtensionInfo] $pExtension) {
        [System.Collections.ArrayList] $SuperExtensions = $this.FindSuperExtensions($pExtension)
        [ExtensionInfo] $SuperExtension = $null
        foreach ($SuperExtension in $SuperExtensions) {
            if ( -not ($SuperExtension.IsInstalled)) {
                $this.Install($SuperExtension)
            }
        }
    }

    [void] UninstallMultiple() {
        $this.Initialise()
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.GetSelectedExtensions()) {
            $this.Uninstall($Extension)
        }
        $this.Finalise()
    }

    hidden [void] Uninstall([ExtensionInfo] $pExtension) {
        $this.InitialiseExtension($pExtension, 'Uninstalling')
        if ($pExtension.IsInstalled) {
            $this.UninstallSubExtensions($pExtension)
            Uninstall-NavApp -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $pExtension.Name -Version $pExtension.Version -PassThru
            $this.UpdateExtensionStatus($pExtension)
            $this.FinaliseExtension($pExtension, ( -not ($pExtension.IsInstalled)), 'Uninstalled', 'Uninstallation failed')
        } else {
            $this.FinaliseExtension($pExtension, [Result]::Success, 'Not installed')
        }
    }

    hidden [void] UninstallSubExtensions([ExtensionInfo] $pExtension) {
        [System.Collections.ArrayList] $SubExtensions = $this.FindSubExtensions($pExtension)
        [ExtensionInfo] $SubExtension = $null
        foreach ($SubExtension in $SubExtensions) {
            if ($SubExtension.IsInstalled) {
                $this.Uninstall($SubExtension)
            }
        }
    }

    [void] UnpublishMultiple([boolean] $pForce) {
        $this.Initialise()
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.GetSelectedExtensions()) {
            $this.Unpublish($Extension, $pForce)
        }
        $this.Finalise()
    }

    hidden [void] Unpublish([ExtensionInfo] $pExtension, [boolean] $pForce) {
        $this.InitialiseExtension($pExtension, 'Un-publishing')
        if (($pExtension.IsPublished) -or ($pForce)) {
            $this.UnpublishSubExtensions($pExtension, $pForce)
            if ($pExtension.IsInstalled) {
                $this.Uninstall($pExtension)
            }
            if ( -not ($pExtension.IsInstalled)) {
                if (($this.Arguments.ExtensionScope -eq 'Tenant') -and ($this.Arguments.MultiTenantServer -eq $true)) {
                    Unpublish-NavApp -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $pExtension.Name -Version $pExtension.Version
                } else {
                    Unpublish-NavApp -ServerInstance $this.Arguments.ServerInstance -Name $pExtension.Name -Version $pExtension.Version
                }
                $this.UpdateExtensionStatus($pExtension)
                $this.FinaliseExtension($pExtension, ( -not ($pExtension.IsPublished)), 'Un-published', 'Un-publishing failed')
            }
        } else {
            $this.FinaliseExtension($pExtension, [Result]::Success, 'Not published')
        }
    }

    hidden [void] UnpublishSubExtensions([ExtensionInfo] $pExtension, [boolean] $pForce) {
        if ( -not ($this.IsNewerVersionInstalled($pExtension))) {
            [System.Collections.ArrayList] $SubExtensions = $this.FindSubExtensions($pExtension)
            [ExtensionInfo] $SubExtension = $null
            foreach ($SubExtension in $SubExtensions) {
                if ($SubExtension.IsPublished) {
                    $this.Unpublish($SubExtension, $pForce)
                }
            }
        }
    }

    hidden [void] Remove() {
        $this.Initialise()
        if ($this.Arguments.AdvancedMode) {
            [System.Collections.ArrayList] $SelectedExtensions = $this.GetSelectedExtensions()
            if ($SelectedExtensions.Count -eq 1) {
                [ExtensionInfo] $Extension = $SelectedExtensions[0]
                $this.InitialiseExtension($Extension, 'Removing')
                if ($Extension.IsInstalled) {
                    Uninstall-NavApp -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $Extension.Name -DoNotSaveData -PassThru
                }
                Sync-NavApp -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $Extension.Name -Mode Clean -PassThru
                if ($Extension.IsPublished) {
                    Unpublish-NavApp -ServerInstance $this.Arguments.ServerInstance -Name $Extension.Name -Version $Extension.Version
                }
                $this.UpdateExtensionStatus($Extension)
                $this.FinaliseExtension($Extension, (( -not ($Extension.IsPublished)) -and ( -not ($Extension.IsInstalled))), 'Removed', 'Removal failed')
            } else {
                $this.FinaliseExtension($Extension, [Result]::Failure, 'You can remove only one extension at a time')
            }
        } else {
            $this.FinaliseExtension($Extension, [Result]::Failure, 'Please, enable advanced mode to use this function')
        }
        $this.Finalise()
    }

    hidden [boolean] IsAnyExtensionSelected() {
        [System.Collections.ArrayList] $SelectedExtensions = $this.GetSelectedExtensions()
        return ($SelectedExtensions.Count -gt 0)
    }
    
    hidden [System.Collections.ArrayList] GetSelectedExtensions() {
        return @($this.Extensions | where { $_.IsSelected })
    }
    
    hidden [ExtensionInfo] FindExtension([System.Collections.ArrayList] $pExtensions, [object] $pExtension) {
        return $pExtensions | where { (($_.Name -eq $pExtension.Name) -and ($_.Version -eq $pExtension.Version)) }
    }

    hidden [void] FindServerExtensions([System.Collections.ArrayList] $pTemporaryExtensions) {
        [string] $ExtensionPublisher = ''
        foreach ($ExtensionPublisher in $this.Arguments.ExtensionPublishers) {
            $Error.Clear()
            [object] $PublishedExtensions = Get-NAVAppInfo -ServerInstance $this.Arguments.ServerInstance -Publisher $ExtensionPublisher
            [object] $PublishedExtension = $null
            foreach ($PublishedExtension in $PublishedExtensions) {
                [object] $Extension = Get-NAVAppInfo -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $PublishedExtension.Name `
                    -Version $PublishedExtension.Version -TenantSpecificProperties
                $pTemporaryExtensions.Add([ExtensionInfo]::new($Extension))
            }
        }
    }
    
    hidden [void] FindFolderExtensions([System.Collections.ArrayList] $pTemporaryExtensions) {
        [object] $Files = Get-ChildItem $this.Arguments.FolderPath -Filter *.app
        [System.IO.FileInfo] $File = $null
        foreach ($File in $Files) {
            [object] $ExtensionInTheFile = Get-NAVAppInfo -Path $File.FullName
            if ($this.Arguments.ExtensionPublishers.Contains($ExtensionInTheFile.Publisher)) {
                [ExtensionInfo] $ExtensionFound = $this.FindExtension($pTemporaryExtensions, $ExtensionInTheFile)
                if ($null -ne $ExtensionFound) {
                    $ExtensionFound.SetFile($File.FullName, $File.Name)
                } else {
                    $pTemporaryExtensions.Add([ExtensionInfo]::new($ExtensionInTheFile, $File.FullName, $File.Name))
                }
            }
        }
    }

    hidden [void] SortAndIndexExtensions([System.Collections.ArrayList] $pTemporaryExtensions) {
        [int] $ExtensionIndex = 0
        [ExtensionInfo] $TemporaryExtension = $null
        foreach ($TemporaryExtension in $pTemporaryExtensions | Sort-Object Name, Version) {
            $ExtensionIndex++
            $TemporaryExtension.SetIndex($ExtensionIndex)
            $this.Extensions.Add($TemporaryExtension)
        }
    }

    hidden [void] UpdateExtensionStatus([ExtensionInfo] $pExtension) {
        [object] $Extension = $null
        if ($this.Arguments.ExtensionScope -eq 'Tenant') {
            $Extension = Get-NAVAppInfo -ServerInstance $this.Arguments.ServerInstance -Tenant $this.Arguments.ServerTenant -Name $pExtension.Name `
                -Version $pExtension.Version -TenantSpecificProperties
        } else {
            $Extension = Get-NAVAppInfo -ServerInstance $this.Arguments.ServerInstance -Name $pExtension.Name -Version $pExtension.Version
        }
        if ($null -ne $Extension) {
            $pExtension.SetExtension($Extension)
        } else {
            $pExtension.ClearPublishedAndInstalledFlags()
            if ( -not ($pExtension.FileExists)) {
                $this.Extensions.Remove($pExtension)
                $this.ReindexExtensions()
            }
        }
    }

    hidden [void] UpdateExtensionAllVersionsStatus([ExtensionInfo] $pExtension) {
        [System.Collections.ArrayList] $ExtensionVersions = @($this.Extensions | where { $_.Id -eq $pExtension.Id })
        [ExtensionInfo] $ExtensionVersion = $null
        foreach ($ExtensionVersion in $ExtensionVersions) {
            $this.UpdateExtensionStatus($ExtensionVersion)
        }
    }

    hidden [void] ReindexExtensions() {
        [int] $Index = 0
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.Extensions) {
            $Index++
            $Extension.SetIndex($Index)
        }
    }

    hidden [void] Initialise() {
        $this.Initialise('')
    }

    hidden [void] Initialise([string] $pMessage) {
        $Error.Clear()
        $this.Result = [ResultToolkit]::ResultWithMessage([Result]::Success, [StringToolkit]::AddSuffixIfNotEmpty($pMessage, '...'))
    }

    hidden [void] Finalise() {
        $this.Finalise($this.Result, '')
    }

    hidden [void] Finalise([string] $pMessage) {
        $this.Finalise($this.Result, $pMessage)
    }

    hidden [void] Finalise([Result] $pResult, [string] $pMessage) {
        $this.Result = [ResultToolkit]::ResultWithMessage($pResult, $pMessage)
        if ($Error.Count -gt 0) {
            $this.Result = [Result]::Failure
        }
    }

    hidden [void] InitialiseExtension([ExtensionInfo] $pExtension, [string] $pMessage) {
        [string] $Message = [StringToolkit]::AddPrefixAndSuffixIfNotEmpty($this.GetExtensionText($pExtension), $pMessage, '...')
        $this.Result = [ResultToolkit]::Combine($this.Result, [ResultToolkit]::ResultWithMessage([Result]::Success, $Message))
    }

    hidden [void] FinaliseExtension([ExtensionInfo] $pExtension, [boolean] $pSuccess, [string] $pSuccessMessage, [string] $pFailureMessage) {
        [Result] $NewResult = [Result]::Empty
        [string] $NewMessage = ''
        if ($pSuccess) {
            $NewResult = [Result]::Success
            $NewMessage = $pSuccessMessage
        } else {
            $NewResult = [Result]::Failure
            $NewMessage = $pFailureMessage
        }
        $this.FinaliseExtension($pExtension, $NewResult, $NewMessage)
    }

    hidden [void] FinaliseExtension([ExtensionInfo] $pExtension, [Result] $pResult, [string] $pMessage) {
        [string] $Message = [StringToolkit]::AddPrefixAndSuffixIfNotEmpty($this.GetExtensionText($pExtension), $pMessage, '.')
        $this.Result = [ResultToolkit]::Combine($this.Result, [ResultToolkit]::ResultWithMessage($pResult, $Message))
    }

    hidden [string] GetExtensionText([ExtensionInfo] $pExtension) {
        if ($null -ne $pExtension) {
            return -Join('[', $pExtension.Name, ' ', $pExtension.Version, '] ')
        } else {
            return ''
        }
    }

    hidden [System.Collections.ArrayList] FindSuperExtensions([ExtensionInfo] $pExtension) {
        [System.Collections.ArrayList] $SuperExtensionTags = @()
        [ExtensionDependencyInfo] $Dependency = $null
        foreach ($Dependency in $pExtension.Dependencies) {
            $SuperExtensionTags.Add([ExtensionTag]::new($Dependency.Id, $Dependency.Name))
        }
        return $this.FindNewestExtensions($SuperExtensionTags)
    }

    hidden [System.Collections.ArrayList] FindSubExtensions([ExtensionInfo] $pExtension) {
        [System.Collections.ArrayList] $SubExtensionTags = @()
        [ExtensionInfo] $Extension = $null
        foreach ($Extension in $this.Extensions) {
            [System.Collections.ArrayList] $SearchResult = @($Extension.Dependencies | where { $_.Id -eq $pExtension.Id })
            if ($SearchResult.Count -gt 0) {
                $SubExtensionTags.Add([ExtensionTag]::new($Extension.Id, $Extension.Name))
            }
        }
        return $this.FindNewestExtensions($SubExtensionTags)
    }

    hidden [System.Collections.ArrayList] FindNewestExtensions([System.Collections.ArrayList] $pExtensionTags) {
        [System.Collections.ArrayList] $NewestExtensions = @()
        [ExtensionTag] $ExtensionTag = $null
        foreach ($ExtensionTag in $pExtensionTags) {
            [System.Collections.ArrayList] $ExtensionsFound = @($this.Extensions | where { $_.Id -eq $ExtensionTag.Id })
            [ExtensionInfo] $NewestExtension = $null
            [Version] $NewestVersion = [Version]::new()
            [ExtensionInfo] $ExtensionFound = $null
            [Version] $VersionFound = $null
            foreach ($ExtensionFound in $ExtensionsFound) {
                $VersionFound = [Version]::new($ExtensionFound.Version)
                if ($VersionFound.IsGreater($NewestVersion)) {
                    $NewestExtension = $ExtensionFound
                    $NewestVersion = $VersionFound
                }
            }
            if ($null -ne $NewestExtension) {
                $NewestExtensions.Add($NewestExtension)
            } else {
                [string] $Message = [string]::Format('Extension "{1}" (ID "{0}") can''t be found', $ExtensionTag.Id, $ExtensionTag.Name)
                $this.Result = [ResultToolkit]::ResultWithMessage([Result]::Failure, $Message)
            }
        }
        return $NewestExtensions
    }

    hidden [boolean] IsNewerVersionInstalled([ExtensionInfo] $pExtension) {
        [boolean] $IsInstalled = $false
        [Version] $Version = [Version]::new($pExtension.Version)
        [System.Collections.ArrayList] $ExtensionsFound = @($this.Extensions | where { $_.Id -eq $pExtension.Id })
        [ExtensionInfo] $ExtensionFound = $null
        [Version] $VersionFound = $null
        foreach ($ExtensionFound in $ExtensionsFound) {
            $VersionFound = [Version]::new($ExtensionFound.Version)
            if ($VersionFound.IsGreater($Version)) {
                $IsInstalled = $true
                break;
            }
        }
        return $IsInstalled
    }

    hidden [void] UpdateDependentExtensions([ExtensionInfo] $pExtension) {
        if ($pExtension.DependentExtensions.Count -eq 0) {
            [System.Collections.ArrayList] $SubExtensions = $this.FindSubExtensions($pExtension)
            [ExtensionInfo] $SubExtension = $null
            [System.Collections.ArrayList] $DependentExtensions = @()
            foreach ($SubExtension in $SubExtensions) {
                [ExtensionDependencyInfo] $DependentExtension = [ExtensionDependencyInfo]::new($SubExtension)
                $DependentExtensions.Add($DependentExtension)
            }
            $pExtension.DependentExtensions = $DependentExtensions
        }
    }
}

class ExtensionInfo : System.IComparable {
    [int] $Index = 0
    [string] $Selector = ''
    [string] $Id = ''
    [string] $Name = ''
    [string] $Brief = ''
    [string] $Description = ''
    [string] $Version = ''
    [string] $DataVersion = ''
    [string] $Publisher = ''
    [string] $Scope = ''
    [boolean] $IsPublished = $false
    [boolean] $IsSynchronised = $false
    [boolean] $IsInstalled = $false
    [boolean] $IsUpgraded = $false
    [boolean] $FileExists = $false
    [string] $FilePath = ''
    [string] $FileName = ''
    [System.Collections.ArrayList] $Dependencies = @()
    [System.Collections.ArrayList] $DependentExtensions = @()
    [boolean] $IsSelected = $false

    ExtensionInfo() {
    }

    ExtensionInfo([object] $pExtension) {
        $this.SetExtension($pExtension)
    }

    ExtensionInfo([object] $pExtension, [string] $pFilePath, [string] $pFileName) {
        $this.SetExtension($pExtension)
        $this.FileExists = $true
        $this.FilePath = $pFilePath
        $this.FileName = $pFileName
    }

    [void] SetIndex([int] $pIndex) {
        $this.Index = $pIndex
        $this.Selector = $this.Index.ToString()
    }

    [void] SetExtension([object] $pExtension) {
        $pExtension | Get-Member
        $this.Id = $pExtension.AppId
        $this.Name = $pExtension.Name
        $this.Brief = $pExtension.Brief
        $this.Description = $pExtension.Description
        $this.Version = $pExtension.Version
        $this.DataVersion = $pExtension.ExtensionDataVersion
        $this.Publisher = $pExtension.Publisher
        $this.IsPublished = $pExtension.IsPublished
        if ($this.IsPublished) {
            $this.Scope = $pExtension.Scope
            $this.IsSynchronised = ($pExtension.SyncState -eq 'Synced')
            if ($this.DataVersion -ne '') {
                $this.IsUpgraded = ($this.DataVersion -eq $this.Version)
            } else {
                $this.IsUpgraded = (($this.IsSynchronised) -and ( -not ($pExtension.NeedsUpgrade)))
            }
            $this.IsInstalled = $pExtension.IsInstalled
        } else {
            $this.ClearPublishedAndInstalledFlags()
        }
        $this.Dependencies = @()
        $this.DependentExtensions = @()
        if ($null -ne $pExtension.Dependencies) {
            foreach ($Dependency in $pExtension.Dependencies) {
                $this.Dependencies.Add([ExtensionDependencyInfo]::new($Dependency))
            }
        }
    }

    [void] ClearPublishedAndInstalledFlags() {
        $this.IsPublished = $false
        $this.Scope = ''
        $this.IsSynchronised = $false
        $this.IsUpgraded = $false
        $this.IsInstalled = $false
    }

    [void] SetFile([string] $pFilePath, [string] $pFileName) {
        $this.FileExists = $true
        $this.FilePath = $pFilePath
        $this.FileName = $pFileName
    }

    [int] CompareTo([object] $pTheOtherExtension)
    {
        if ($null -ne $pTheOtherExtension) {
            if (($this.Name -eq $pTheOtherExtension.Name) -and ($this.Version -eq $pTheOtherExtension.Version)) {
                return 0
            } else {
                return 1
            }
        } else {
            return -1
        }
    }

    [System.Collections.ArrayList] GetProperties() {
        [System.Collections.ArrayList] $Properties = @()
        [Converter] $Converter = [Converter]::new()
        $Properties.Add([Property]::new('ID', $this.Id))
        $Properties.Add([Property]::new('Name', $this.Name))
        $Properties.Add([Property]::new('Brief', $this.Brief))
        $Properties.Add([Property]::new('Description', $this.Description))
        $Properties.Add([Property]::new('Version', $this.Version))
        $Properties.Add([Property]::new('Data Version', $this.DataVersion))
        $Properties.Add([Property]::new('Publisher', $this.Publisher))
        $Properties.Add([Property]::new('Scope', $this.Scope))
        $this.AddListProperty($Properties, $this.Dependencies, 'Dependencies')
        $this.AddListProperty($Properties, $this.DependentExtensions, 'Dependent Extensions')
        $Properties.Add([Property]::new('Is Published', $Converter.FormatBoolean($this.IsPublished)))
        $Properties.Add([Property]::new('Is Synchronised', $Converter.FormatBoolean($this.IsSynchronised)))
        $Properties.Add([Property]::new('Is Upgraded', $Converter.FormatBoolean($this.IsUpgraded)))
        $Properties.Add([Property]::new('Is Installed', $Converter.FormatBoolean($this.IsInstalled)))
        $Properties.Add([Property]::new('File Exists', $Converter.FormatBoolean($this.FileExists)))
        $Properties.Add([Property]::new('File Name', $this.FileName))
        return $Properties
    }

    [void] AddListProperty([System.Collections.ArrayList] $pProperties, [System.Collections.ArrayList] $pListProperty, [string] $pPropertyName) {
        [string] $PropertyName = $pPropertyName
        if (($null -ne $pListProperty) -and ($pListProperty.Count -gt 0)) {
            [object] $ListPropertyItem = $null
            foreach ($ListPropertyItem in $pListProperty) {
                $pProperties.Add([Property]::new($PropertyName, $ListPropertyItem))
                $PropertyName = ''
            }
        } else {
            $pProperties.Add([Property]::new($PropertyName, 'None'))
        }
    }

    [string] ToString() {
        return [string]::Format('{0} {1}', $this.Name, $this.Publisher)
    }
}

class ExtensionDependencyInfo {
    [string] $Id = ''
    [string] $Name = ''
    [string] $Publisher = ''
    [string] $Version = ''

    ExtensionDependencyInfo() {
    }

    ExtensionDependencyInfo([ExtensionInfo] $pExtension) {
        $this.Id = $pExtension.Id
        $this.Name = $pExtension.Name
        $this.Publisher = $pExtension.Publisher
        $this.Version = $pExtension.Version
    }

    ExtensionDependencyInfo([object] $pDependency) {
        $this.Id = $pDependency.AppId
        $this.Name = $pDependency.Name
        $this.Publisher = $pDependency.Publisher
        $this.Version = $pDependency.MinVersion
    }

    [string] ToString() {
        return [string]::Format('{0} {1}', $this.Name, $this.Version)
    }
}

class ExtensionTag {
    [string] $Id = ''
    [string] $Name = ''

    ExtensionTag() {
    }

    ExtensionTag([string] $pNewId, [string] $pName) {
        $this.Id = $pNewId
        $this.Name = $pName
    }
}

class Table {
    [string] $BordersColour = 'Gray'
    [string] $Header = ''
    [string] $HeaderColour = 'White'
    [System.Collections.ArrayList] $Columns = @()
    [string] $ColumnHeadersColour = 'White'
    [boolean] $Initialised = $false
    [int] $Width = 0
    [boolean] $ShowColumnHeaders = $false

    Table([string] $pHeader) {
        $this.Header = $pHeader
    }

    Table([string] $pHeader, [System.Collections.ArrayList] $pColumns) {
        $this.Header = $pHeader
        $this.Columns = $pColumns
    }

    Table([string] $pHeader, [string] $pHeaderColour) {
        $this.Header = $pHeader
        $this.HeaderColour = $pHeaderColour
    }

    Table([string] $pHeader, [string] $pHeaderColour, [System.Collections.ArrayList] $pColumns) {
        $this.Header = $pHeader
        $this.HeaderColour = $pHeaderColour
        $this.Columns = $pColumns
    }

    [void] AddColumn([TableColumn] $pColumn) {
        $this.Columns.Add($pColumn)
    }

    [void] Setwidth([int] $pWidth) {
        $this.Width = $pWidth
        $this.Initialised = $true
    }

    [void] DrawHeader() {
        $this.Initialise()
        $this.Draw('┌', '', '─', $this.BordersColour, '┐')
        if ($this.Header -ne '') {
            $this.Draw('│', -join(' ', $this.Header, ' '), ' ', $this.HeaderColour, '│')
            $this.Draw('├', '', '─', $this.BordersColour, '┤')
        }
        if ($this.ShowColumnHeaders) {
            Write-Host '│ ' -ForegroundColor $this.BordersColour -NoNewline 
            [TableColumn] $Column = $null
            foreach ($Column in $this.Columns) {
                Write-Host $Column.Header.PadRight($Column.Width, ' ') -ForegroundColor $this.ColumnHeadersColour -NoNewline
            }
            Write-Host ' │' -ForegroundColor $this.BordersColour #
            $this.Draw('├', '', '─', $this.BordersColour, '┤')
        }
    }

    [void] DrawRow([System.Collections.ArrayList] $pValues) {
        $this.DrawRow($pValues, $false)
    }

    [void] DrawRow([System.Collections.ArrayList] $pValues, [boolean] $pSelected) {
        Write-Host '│ ' -ForegroundColor $this.BordersColour -NoNewline
        [int] $Index = 0
        [TableColumn] $Column = $null
        [string] $Value = ''
        [string] $Colour = ''
        foreach ($Value in $pValues) {
            $Column = $this.Columns[$Index]
            if ($pSelected) {
                $Colour = $Column.SelectedColour
            } else {
                $Colour = $Column.Colour
            }
            if ($Value.Length -gt $Column.Width) {
                $Value = -Join($Value.Substring(0, $Column.Width - 3), '...')
            }
            Write-Host $Value.PadRight($Column.Width, ' ') -ForegroundColor $Colour -NoNewline
            $Index++
        }
        Write-Host ' │' -ForegroundColor $this.BordersColour 
    }

    [void] DrawRowBegin() {
        Write-Host '│ ' -ForegroundColor $this.BordersColour -NoNewline
    }
    
    [void] DrawRowEnd() {
        Write-Host ' │' -ForegroundColor $this.BordersColour
    }
    
    [void] DrawSeparator() {
        Write-Host (-Join('│ ', ''.PadRight($this.Width - 4, '─'), ' │')) -ForegroundColor $this.BordersColour
    }

    [void] DrawFooter() {
        $this.Draw('└', '', '─', $this.BordersColour, '┘')
    }

    [void] Draw([string] $pLeftBorder, [string] $pText, [string] $pFiller, [string] $pTextColour, [string] $pRightBorder) {
        Write-Host $pLeftBorder -ForegroundColor $this.BordersColour -NoNewline 
        Write-Host $pText.PadRight($this.Width-2, $pFiller) -ForegroundColor $pTextColour -NoNewline
        Write-Host $pRightBorder -ForegroundColor $this.BordersColour 
    }

    [void] Initialise() {
        if ( -not ($this.Initialised)) {
            $this.Width = 0
            $this.ShowColumnHeaders = $false
            [TableColumn] $Column = $null
            foreach ($Column in $this.Columns) {
                $this.Width += $Column.Width
                if ($Column.Header -ne '') {
                    $this.ShowColumnHeaders = $true
                }
            }
            $this.Width += 4
            $this.Initialised = $true
        }
    }
}

class TableColumn {
    [string] $Header = ''
    [int] $Width = 0
    [string] $Colour = 'White'
    [string] $SelectedColour = 'Yellow'

    TableColumn([string] $pHeader, [int] $pWidth) {
        $this.Header = $pHeader
        $this.Width = $pWidth
        $this.Colour = 'White'
    }

    TableColumn([string] $pHeader, [int] $pWidth, [string] $pColour) {
        $this.Header = $pHeader
        $this.Width = $pWidth
        $this.Colour = $pColour
    }

    TableColumn([string] $pHeader, [int] $pWidth, [string] $pColour, [string] $pSelectedColour) {
        $this.Header = $pHeader
        $this.Width = $pWidth
        $this.Colour = $pColour
        $this.SelectedColour = $pSelectedColour
    }
}

class Menu {
    [string] $SelectorColour = 'Cyan'
    [string] $TextColour = 'Yellow'
    [System.Collections.ArrayList] $Items = @()
    [int] $Width = 0
    [int] $WidthOfItems = 0
    [boolean] $FirstItem = $false

    Menu([int] $pWidth) {
        $this.Width = $pWidth
    }

    Menu([System.Collections.ArrayList] $pItems) {
        $this.Items = $pItems
    }

    Menu([int] $pWidth, [System.Collections.ArrayList] $pItems) {
        $this.Width = $pWidth
        $this.Items = $pItems
    }

    Menu([string] $pSelectorColour, [string] $pTextColour, [System.Collections.ArrayList] $pItems) {
        $this.SelectorColour = $pSelectorColour
        $this.TextColour = $pTextColour
        $this.Items = $pItems
    }

    [void] AddItems([System.Collections.ArrayList] $pNewItems) {
        [MenuItem] $NewItem = $null
        foreach ($NewItem in $pNewItems) {
            $this.Items.Add($NewItem)
        }
    }

    [void] Draw() {
        [Table] $Table = [Table]::new('')
        $Table.Setwidth($this.Width)
        $Table.DrawHeader()
        $Table.DrawRowBegin()
        $this.WidthOfItems = 4
        $this.FirstItem = $true
        [MenuItem] $Item = $null
        foreach ($Item in $this.items) {
            if ($Item.IsActive) {
                switch ($Item.Type) {
                    Item {
                        if ($this.FirstItem) {
                            $this.FirstItem = $false
                        } else {
                            $this.DrawText('  ', '')
                        }
                        $this.DrawText($Item.Selector, $this.SelectorColour)
                        $this.DrawText(' ', '')
                        $this.DrawText($Item.Text, $this.TextColour)
                    }
                    NewLine {
                        $this.DrawTheRestOfTheLine($Table, $true)
                    }
                    Separator {
                        $this.DrawTheRestOfTheLine($Table, $false)
                        $Table.DrawSeparator()
                        $Table.DrawRowBegin()
                    }
                }
            }
        }
        if ($this.Width -gt $this.WidthOfItems) {
            $this.DrawTheRestOfTheLine($Table, $false)
        }
        $Table.DrawFooter()
    }

    [void] DrawText([string] $pText, [string] $pColour) {
        if ($pColour -ne '') {
            Write-Host $pText -ForegroundColor $pColour -NoNewline
        } else {
            Write-Host $pText -NoNewline
        }
        $this.WidthOfItems += $pText.Length
    }

    [void] DrawTheRestOfTheLine([Table] $pTable, [boolean] $pDrawNextLine) {
        Write-Host ''.PadRight($this.Width - $this.WidthOfItems, ' ') -NoNewline
        $pTable.DrawRowEnd()
        if ($pDrawNextLine) {
            $pTable.DrawRowBegin()
        }
        $this.WidthOfItems = 4
        $this.FirstItem = $true
    }
}

class MenuItem {
    [string] $Selector = ''
    [string] $Text = ''
    [string] $Description = ''
    [Command] $Command = [Command]::Empty
    [MenuItemType] $Type = [MenuItemType]::Item
    [boolean] $IsActive = $true

    MenuItem([string] $pSelector, [string] $pText, [string] $pDescription, [Command] $pCommand) {
        $this.Selector = $pSelector
        $this.Text = $pText
        $this.Description = $pDescription
        $this.Command = $pCommand
    }

    MenuItem([string] $pSelector, [string] $pText, [string] $pDescription, [Command] $pCommand, [boolean] $pIsActive) {
        $this.Selector = $pSelector
        $this.Text = $pText
        $this.Description = $pDescription
        $this.Command = $pCommand
        $this.IsActive = $pIsActive
    }

    MenuItem([MenuItemType] $pType) {
        $this.Type = $pType
    }

    MenuItem([MenuItemType] $pType, [boolean] $pIsActive) {
        $this.Type = $pType
        $this.IsActive = $pIsActive
    }
}

class Property {
    [string] $Name = ''
    [string] $Value = ''

    Property([string] $pName, [string] $pValue) {
        $this.Name = $pName
        $this.Value = $pValue
    }
}

class PropertyColumniser {
    [System.Collections.ArrayList] $Rows = @()
    
    PropertyColumniser([System.Collections.ArrayList] $pProperties, [int] $pNoOfColumns) {
        [int] $NoOfRows = [Math]::Ceiling($pProperties.Count / $pNoOfColumns)
        [int] $CurrentRow = 0
        [Property] $Property = $null
        [System.Collections.ArrayList] $Row = $null
        foreach ($Property in $pProperties) {
            if ($CurrentRow -ge $NoOfRows) {
                $CurrentRow = 0
            }
            if ($this.Rows.Count -lt $CurrentRow + 1) {
                $Row = @()
                $Row.Add($Property.Name)
                $Row.Add($Property.Value)
                $this.Rows.Add($Row)
            } else {
                $Row = $this.Rows[$CurrentRow]
                $Row.Add($Property.Name)
                $Row.Add($Property.Value)
            }
            $CurrentRow++
        }
    }
}

class Path {
    [string] $FolderSeparator = '\'
    [string] $FileExtensionSeparator = '.'

    [string] GetFolder([string] $pPath) {
        [string] $Folder = $pPath
        [int] $FolderSeparatorIndex = $pPath.LastIndexOf($this.FolderSeparator)
        if ($FolderSeparatorIndex -ge 0) {
            $Folder = $pPath.Substring(0, $FolderSeparatorIndex)
        }
        return $Folder
    }

    [string] GetFileName([string] $pPath) {
        [string] $FileName = $pPath
        [int] $FolderSeparatorIndex = $pPath.LastIndexOf($this.FolderSeparator)
        if ($FolderSeparatorIndex -ge 0) {
            $FileName = $pPath.Substring($FolderSeparatorIndex + 1)
        }
        return $FileName
    }

    [string] GetFileNameWithoutExtension([string] $pPath) {
        [string] $FileName = $this.GetFileName($pPath)
        [string] $FileNameWithoutExtension = $FileName
        [int] $FileExtensionSeparatorIndex = $FileName.LastIndexOf($this.FileExtensionSeparator)
        if ($FileExtensionSeparatorIndex -ge 0) {
            $FileNameWithoutExtension = $FileName.Substring(0, $FileExtensionSeparatorIndex)
        }
        return $FileNameWithoutExtension
    }

    [string] GetFileExtension([string] $pPath) {
        [string] $FileName = $this.GetFileName($pPath)
        [string] $Extension = $FileName
        [int] $FileExtensionSeparatorIndex = $FileName.LastIndexOf($this.FileExtensionSeparator)
        if ($FileExtensionSeparatorIndex -ge 0) {
            $Extension = $pPath.Substring($FileExtensionSeparatorIndex + 1)
        }
        return $Extension
    }

    [string] Combine([string] $pPart1, [string] $pPart2) {
        [boolean] $AddSeparator = (($pPart1 -ne '') -and ( -not ($pPart1.EndsWith($this.FolderSeparator))) `
            -and ($pPart2 -ne '') -and ( -not ($pPart2.StartsWith($this.FolderSeparator))))
        [string] $Path = $pPart1
        if ($AddSeparator) {
            $Path += $this.FolderSeparator
        }
        $Path += $pPart2
        return $Path
    }

    [string] CreateFileNameWithExtension([string] $pFileNameWithoutExtension, [string] $pExtension) {
        [boolean] $AddSeparator = (( -not ($pFileNameWithoutExtension.EndsWith($this.FileExtensionSeparator))) `
            -and ($pExtension -ne '') -and ( -not ($pExtension.StartsWith($this.FileExtensionSeparator))))
        [string] $FileName = $pFileNameWithoutExtension
        if ($AddSeparator) {
            $FileName += $this.FileExtensionSeparator
        }
        $FileName += $pExtension
        return $FileName
    }
}

class Converter {
    Converter() {
    }

    [string] FormatBoolean([boolean] $pValue) {
        if ($pValue) {
            return '■'
        } else {
            return '□'
        }
    }

    [string] FormatAndPadBoolean([boolean] $pValue, [int] $pPad) {
        if ($pValue) {
            return '■'.PadLeft($pPad, ' ')
        } else {
            return '□'.PadLeft($pPad, ' ')
        }
    }

    [string] FormatArrayList([System.Collections.ArrayList] $pValue) {
        [string] $String = ''
        if ($pValue -ne $null) {
            [object] $Element = $null
            foreach ($Element in $pValue) {
                if ($String -ne '') {
                    $String = -Join($String, ', ')
                }
                if ($Element -ne $null) {
                    $String = -Join($String, $Element.ToString())
                } else {
                    $String = -Join($String, 'null')
                }            
            }
        } else {
            $String = 'null'
        }
        return $String
    }
}

class ResultToolkit {
    static [Result] ResultWithMessage([Result] $pResult, [string] $pMessage) {
        if ($pMessage -ne '') {
            switch ($pResult) {
                Success {
                    Write-Host $pMessage
                }
                Confirmation {
                    Write-Host $pMessage
                }
                Failure {
                    Write-Host (-Join('ERROR: ', $pMessage)) -ForegroundColor Red
                }
                Warning {
                    Write-Warning $pMessage
                }
            }
        }
        return $pResult
    }

    static [Result] Combine([Result] $pResult, [Result] $pNewResult) {
        switch ($pNewResult) {
            Success {
                if ($pResult -eq [Result]::Empty) {
                    $pResult = $pNewResult
                }
            }
            Confirmation {
                if (($pResult -eq [Result]::Empty) -or ($pResult -eq [Result]::Success)) {
                    $pResult = $pNewResult
                }
            }
            Failure {
                $pResult = $pNewResult
            }
            Warning {
                if ($pResult -ne [Result]::Failure) {
                    $pResult = $pNewResult
                }
            }
        }
        return $pResult
    }

    static [boolean] RequiresConfirmation([Result] $pResult) {
        return (($pResult -eq [Result]::Confirmation) -or ($pResult -eq [Result]::Failure) -or ($pResult -eq [Result]::Warning))
    }
}

class StringToolkit {    
    static [string] Default([string] $pText, [string] $pDefaultText) {
        if ($pText -ne '') {
            return $pText
        } else {
            return $pDefaultText
        }
    }
    
    static [string] Indent([string] $pText, [int] $pIndentation) {
        return -Join(' ' * $pIndentation, $pText)
    }

    static [string] AddPrefixAndSuffixIfNotEmpty([string] $pPrefix, [string] $pMessage, [string] $pSuffix) {
        if ($pMessage -ne '') {
            return -Join($pPrefix, $pMessage, $pSuffix)
        } else {
            return ''
        }
    }

    static [string] AddPrefixIfNotEmpty([string] $pPrefix, [string] $pMessage) {
        if ($pMessage -ne '') {
            return -Join($pPrefix, $pMessage)
        } else {
            return ''
        }
    }

    static [string] AddSuffixIfNotEmpty([string] $pMessage, [string] $pSuffix) {
        if ($pMessage -ne '') {
            return -Join($pMessage, $pSuffix)
        } else {
            return ''
        }
    }
}

class Version {
    [int] $Major = 0
    [int] $Minor = 0
    [int] $Build = 0
    [int] $Revision = 0

    Version() {
    }

    Version([string] $pVersionText) {
        [System.Collections.ArrayList] $VersionTextParts = $pVersionText.Split('.')
        if ($VersionTextParts.Count -ge 1) {
            $this.Major = [int]::Parse($VersionTextParts[0])
        }
        if ($VersionTextParts.Count -ge 1) {
            $this.Minor = [int]::Parse($VersionTextParts[1])
        }
        if ($VersionTextParts.Count -ge 1) {
            $this.Build = [int]::Parse($VersionTextParts[2])
        }
        if ($VersionTextParts.Count -ge 1) {
            $this.Revision = [int]::Parse($VersionTextParts[3])
        }
    }

    [boolean] IsEqual([Version] $pVersion) {
        return ($this.Compare($pVersion) -eq 0)
    }

    [boolean] IsNotEqual([Version] $pVersion) {
        return ($this.Compare($pVersion) -ne 0)
    }

    [boolean] IsGreater([Version] $pVersion) {
        return ($this.Compare($pVersion) -eq 1)
    }

    [boolean] IsGreaterOrEqual([Version] $pVersion) {
        return ($this.Compare($pVersion) -ge 0)
    }

    [boolean] IsLower([Version] $pVersion) {
        return ($this.Compare($pVersion) -ge -1)
    }

    [boolean] IsLowerOrEqual([Version] $pVersion) {
        return ($this.Compare($pVersion) -le 0)
    }

    [int] Compare([Version] $pVersion) {
        [int] $Result = [IntToolkit]::Compare($this.Major, $pVersion.Major)
        if ($Result -eq 0) {
            $Result = [IntToolkit]::Compare($this.Minor, $pVersion.Minor)
        }
        if ($Result -eq 0) {
            $Result = [IntToolkit]::Compare($this.Build, $pVersion.Build)
        }
        if ($Result -eq 0) {
            $Result = [IntToolkit]::Compare($this.Revision, $pVersion.Revision)
        }
        return $Result
    }
}

class IntToolkit {
    static [int] Compare([int] $pFirst, [int] $pLast) {
        if ($pFirst -gt $pLast) {
            return 1
        } else {
            if ($pFirst -lt $pLast) {
                return -1
            }
        }
        return 0
    }
}
