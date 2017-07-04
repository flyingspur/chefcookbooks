#
# Cookbook:: windows_ex2
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

for feature in ["Web-Server","Web-Http-Redirect","Web-Asp-Net45","Web-Log-Libraries","Web-Http-Tracing","Web-Custom-Logging","Web-Basic-Auth","Web-Mgmt-Service","Web-Mgmt-Console","File-Services"] do
    powershell_script 'Install Web Server features' do
        code "Add-WindowsFeature #{feature}"
        not_if "(Get-WindowsFeature -Name #{feature}).Installed"
    end
end

directory 'C:\inetpub\ClientWebSite'

powershell_script 'Create Application Pool' do
    code <<-EOH
        Import-Module WebAdministration
        $appPool = New-Item -Path "IIS:/AppPools/MyAppPool"
        $appPool | Set-ItemProperty -Name "managedRuntimeVersion" -Value "v4.0"
        $appPool | Set-ItemProperty -Name "managedPipelineMode" -Value 1
        EOH
    not_if <<-EOH
        Import-Module WebAdministration
        Test-Path IIS:/AppPools/MyAppPool -pathType container
        EOH
end

powershell_script 'Create IIS Website Root' do
    code <<-EOH
        Import-Module WebAdministration
        New-Item "IIS:/Sites/Root" -bindings @{protocol="http";bindingInformation=":80:" + "Root"}
        EOH
    not_if <<-EOH
        Import-Module WebAdministration
        Test-Path "IIS:/Sites/Root" -pathType container
        EOH
end

powershell_script 'Create IIS Web Application' do
    code <<-EOH
        Import-Module WebAdministration
        New-WebApplication -Name "ClientWebSite" -ApplicationPool "MyAppPool" -Site "Root" -PhysicalPath 'C:/inetpub/ClientWebSite'
        EOH
    not_if <<-EOH
        Import-Module WebAdministration
        Test-Path "IIS:/Sites/Root/ClientWebSite" -pathType container
        EOH
end

for iis_node in ["Root", "Root/ClientWebSite"] do
    powershell_script 'Set Application Pool' do
        code <<-EOH
            Import-Module WebAdministration
            Set-ItemProperty "IIS:/Sites/#{iis_node}" -Name "applicationPool" -Value "MyAppPool"
            EOH
        not_if <<-EOH
            Import-Module WebAdministration
            (Get-ItemProperty "IIS:/Sites/#{iis_node}" -Name "applicationPool") -ceq "MyAppPool"
            EOH
    end
end
