#
# Cookbook:: persona
# Recipe:: firefox
#

[
  node['persona'].fetch('personal_user', nil),
  node['persona'].fetch('guest_user', nil)
].compact.each do |params|
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
