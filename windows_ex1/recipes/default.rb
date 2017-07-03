#
# Cookbook:: test
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# 
install_app 'sequencegenerator' do
    port 443
    username 'serverapp'
    action :create
end
