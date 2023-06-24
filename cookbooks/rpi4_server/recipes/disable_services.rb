#
# Cookbook:: rpi4_server
# Recipe:: disable_services
#

systemd_unit 'chef-client.service' do
  action :stop
end

systemd_unit 'chef-client.service' do
  action :disable
end

systemd_unit 'snapd.service' do
  action :stop
end

systemd_unit 'snapd.service' do
  action :disable
end

systemd_unit 'cloud-init.service' do
  action :stop
end

systemd_unit 'cloud-init.service' do
  action :disable
end

systemd_unit 'unattended-upgrades.service' do
  action :stop
end

systemd_unit 'unattended-upgrades.service' do
  action :disable
end
