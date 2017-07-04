resource_name :install_app
property :appname, String, name_property: true
property :username, String, required: true
property :port, Integer, required: true

action :create do
    directory 'c:/apps' do
        action :create
    end
    directory 'c:/logfiles' do
        action :create
    end

    directory "c:/apps/#{appname}" do
        action :create
    end

    directory "c:/logfiles/#{appname}" do
        action :create
    end

    powershell_script "OpenPort_Firewall_#{appname}" do
      code <<-EOH
        netsh advfirewall firewall add rule name="#{appname} #{port}" dir=in action=allow protocol=TCP localport=#{port}
      EOH
    end

    user "#{username}" do
       password "test$Password1Now"
       action :create
       notifies :run, "powershell_script[Grant log on as a service permission]", :immediately
    end

    # grant permission to run as a service
        powershell_script "Grant log on as a service permission" do
         code <<-EOH
           $username = "vm\\ServerApp"
           $tempPath = [System.IO.Path]::GetTempPath()
           $import = Join-Path -Path $tempPath -ChildPath "import.inf"
           if(Test-Path $import) { Remove-Item -Path $import -Force }
           $export = Join-Path -Path $tempPath -ChildPath "export.inf"
           if(Test-Path $export) { Remove-Item -Path $export -Force }
           $secedt = Join-Path -Path $tempPath -ChildPath "secedt.sdb"
           if(Test-Path $secedt) { Remove-Item -Path $secedt -Force }

           try {
               Write-Host ("Granting SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
               $sid = ((New-Object System.Security.Principal.NTAccount($username)).Translate([System.Security.Principal.SecurityIdentifier])).Value
               secedit /export /cfg $export
               $sids = (Select-String $export -Pattern "SeServiceLogonRight").Line

               foreach ($line in @("[Unicode]", "Unicode=yes", "[System Access]", "[Event Audit]", "[Registry Values]", "[Version]", "signature=`"`$CHICAGO$`"", "Revision=1", "[Profile Description]", "Description=GrantLogOnAsAService security template", "[Privilege Rights]", "SeServiceLogonRight = *$sids,*$sid")){
                   Add-Content $import $line
               }

               secedit /import /db $secedt /cfg $import
               secedit /configure /db $secedt
               gpupdate /force
               Remove-Item -Path $import -Force
               Remove-Item -Path $export -Force
               Remove-Item -Path $secedt -Force
           } catch {
               Write-Host ("Failed to grant SeServiceLogonRight to user account: {0} on host: {1}." -f $username, $computerName)
               $error[0]
           }
         EOH
        end

        # install
        powershell_script "Installing #{appname} service" do
         code <<-EOH
            $service = Get-Service -Name #{appname} -ErrorAction SilentlyContinue
            if ($service.Length -eq 0) {
              New-Service -Name #{appname} -BinaryPathName 'c:/apps/#{appname}/#{appname}.exe -k netsvcs' -DisplayName #{appname} -StartupType Automatic
              }
            EOH
        end
end
