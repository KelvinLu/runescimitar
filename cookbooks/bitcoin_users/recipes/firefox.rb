#
# Cookbook:: bitcoin_users
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

[
  node['bitcoin_users'].fetch('personal_user'),
  node['bitcoin_users'].fetch('guest_user')
].each do |params|
  username = params.fetch('name')

  directory 'firefox ~/.mozilla' do
    path lazy { File.join(Dir.home(username), '.mozilla') }
  end

  directory 'firefox ~/.mozilla/firefox' do
    path lazy { File.join(Dir.home(username), '.mozilla', 'firefox') }
  end

  directory 'firefox ~/.cache' do
    path lazy { File.join(Dir.home(username), '.cache') }
  end

  directory 'firefox ~/.cache/mozilla' do
    path lazy { File.join(Dir.home(username), '.cache', 'mozilla') }
  end

  directory 'firefox ~/.cache/mozilla/firefox' do
    path lazy { File.join(Dir.home(username), '.cache', 'mozilla', 'firefox') }
  end
end
