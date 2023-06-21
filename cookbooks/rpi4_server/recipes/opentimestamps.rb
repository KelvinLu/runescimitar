#
# Cookbook:: rpi4_server
# Recipe:: opentimestamps
#
# Copyright:: 2022, The Authors, All Rights Reserved.

operator_user = node['rpi4_server'].fetch('operator_user')

include_recipe 'applications::python'

execute 'pip3 install opentimestamps-client' do
  command %w[pip3 install opentimestamps-client]

  only_if { `which ots`.empty? }
end
