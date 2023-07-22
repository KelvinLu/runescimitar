#
# Cookbook:: applications
# Recipe:: firefox
#

apt_repository 'mozillateam' do
  uri 'ppa:mozillateam/ppa'
end

cookbook_file '/usr/local/bin/kiosk-firefox' do
  source 'kiosk-firefox'

  mode '0755'
end

file '/etc/apt/preferences.d/mozilla-firefox' do
  content <<~CONFIG
    Package: *
    Pin: release o=LP-PPA-mozillateam
    Pin-Priority: 1001
  CONFIG

  mode '0644'
end

apt_package 'firefox' do
  action :install
end
