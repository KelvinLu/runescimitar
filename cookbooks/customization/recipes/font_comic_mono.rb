#
# Cookbook:: customization
# Recipe:: font_comic_mono
#
# Copyright:: 2022, The Authors, All Rights Reserved.

directory '/usr/share/fonts/TTF/' do
  mode    '0755'
  action  :create
end

remote_file '/usr/share/fonts/TTF/ComicMono.ttf' do
  source    'https://dtinth.github.io/comic-mono-font/ComicMono.ttf'
  checksum  '3bc1425e922a16abf0ec767effe4d0268439b4c0dce98432e07d15f5dad57196'

  mode    '0644'
  action  :create_if_missing

  notifies :run, 'execute[fc-cache]', :delayed
end

remote_file '/usr/share/fonts/TTF/ComicMono-Bold.ttf' do
  source    'https://dtinth.github.io/comic-mono-font/ComicMono-Bold.ttf'
  checksum  '2396da69ddc7f5212caa0ede627fb2fbb2319a15cc6877249e109e1fd7e60e7e'

  mode    '0644'
  action  :create_if_missing

  notifies :run, 'execute[fc-cache]', :delayed
end

execute 'fc-cache' do
  command ['fc-cache', '-f']

  action :nothing
end
