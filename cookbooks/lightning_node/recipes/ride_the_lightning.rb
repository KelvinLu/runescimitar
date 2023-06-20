#
# Cookbook:: lightning_node
# Recipe:: ride_the_lightning
#
# Copyright:: 2022, The Authors, All Rights Reserved.

include_recipe 'rpi4_server::nginx'
include_recipe 'rpi4_server::ufw'
include_recipe 'applications::nodejs'
