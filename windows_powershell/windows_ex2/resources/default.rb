resource_name :iis_install
property :webroot, String, name_property: true, required: true
property :apppoolname, String
property :webappname, String

action :create do
    for feature in ["Web-Server","Web-Http-Redirect","Web-Asp-Net45","Web-Log-Libraries","Web-Http-Tracing","Web-Custom-Logging","Web-Basic-Auth","Web-Mgmt-Service","Web-Mgmt-Console","File-Services"] do
        powershell_script "Install Web Server features - #{feature}" do
            code "Add-WindowsFeature #{feature}"
            not_if "(Get-WindowsFeature -Name #{feature}).Installed"
        end
    end

    directory "#{new_resource.webroot}/#{new_resource.webappname}"

    powershell_script "Create Application Pool - #{new_resource.apppoolname}" do
        code <<-EOH
            Import-Module WebAdministration
            New-Item -Path "IIS:/AppPools/#{new_resource.apppoolname}"
            EOH
        not_if <<-EOH
            Import-Module WebAdministration
            Test-Path IIS:/AppPools/#{new_resource.apppoolname} -pathType container
            EOH
    end

    powershell_script "Application Pool - managedRuntimeVersion - #{new_resource.apppoolname}" do
        code <<-EOH
            Import-Module WebAdministration
            Set-ItemProperty "IIS:/AppPools/#{new_resource.apppoolname}" -Name "managedRuntimeVersion" -Value "v4.0"
            EOH
        not_if <<-EOH
            Import-Module WebAdministration
            (Get-ItemProperty IIS:/AppPools/#{new_resource.apppoolname} -Name "managedRuntimeVersion") -ceq "v4.0"
            EOH
    end

    powershell_script "Application Pool - managedPipelineMode - #{new_resource.apppoolname}" do
        code <<-EOH
            Import-Module WebAdministration
            Set-ItemProperty "IIS:/AppPools/#{new_resource.apppoolname}" -Name "managedPipelineMode" -Value 1
            EOH
        not_if <<-EOH
            Import-Module WebAdministration
            (Get-ItemProperty IIS:/AppPools/#{new_resource.apppoolname} -Name "managedPipelineMode") -ceq "Classic"
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

    powershell_script "Create IIS Web Application - #{new_resource.webappname}" do
        code <<-EOH
            Import-Module WebAdministration
            New-WebApplication -Name "#{new_resource.webappname}" -ApplicationPool "#{new_resource.apppoolname}" -Site "Root" -PhysicalPath 'C:/inetpub/#{new_resource.webappname}'
            EOH
        not_if <<-EOH
            Import-Module WebAdministration
            Test-Path "IIS:/Sites/Root/#{new_resource.webappname}" -pathType container
            EOH
    end

    for iis_node in ["Root", "Root/#{new_resource.webappname}"] do
        powershell_script 'Set Application Pool' do
            code <<-EOH
                Import-Module WebAdministration
                Set-ItemProperty "IIS:/Sites/#{iis_node}" -Name "applicationPool" -Value "#{new_resource.apppoolname}"
                EOH
            not_if <<-EOH
                Import-Module WebAdministration
                (Get-ItemProperty "IIS:/Sites/#{iis_node}" -Name "applicationPool") -ceq "#{new_resource.apppoolname}"
                EOH
        end
    end
end
