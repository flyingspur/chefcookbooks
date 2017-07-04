#
# Cookbook:: windows_ex2
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

iis_install 'Install IIS and Web app setup' do
    webroot 'C:/inetpub'
    apppoolname 'ClientAppPool'
    webappname 'ClientWebSite'
    action :create
end
