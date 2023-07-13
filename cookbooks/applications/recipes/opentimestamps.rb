#
# Cookbook:: applications
# Recipe:: opentimestamps
#

include_recipe 'applications::python'

execute 'pip3 install opentimestamps-client' do
  command %w[pip3 install opentimestamps-client]

  only_if { `which ots`.empty? }
end
