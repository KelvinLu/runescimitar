#
# Cookbook:: bitcoin_users
# Recipe:: firefox
#

apt_package 'firefox' do
  action :install
end

cookbook_file '/usr/local/bin/kiosk-firefox' do
  source 'kiosk-firefox'

  mode '0755'
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
