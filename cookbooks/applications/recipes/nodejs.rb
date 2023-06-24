#
# Cookbook:: applications
# Recipe:: nodejs
#

NODEJS_PACKAGE_ARCHIVE = 'https://nodejs.org/dist/v18.16.0/node-v18.16.0-linux-arm64.tar.xz'

directory '/var/opt/nodejs' do
  mode '0755'
end

remote_file 'download nodejs' do
  path File.join('/var/opt/nodejs', File.basename(NODEJS_PACKAGE_ARCHIVE))
  source NODEJS_PACKAGE_ARCHIVE

  mode '0644'

  checksum 'c81dfa0bada232cb4583c44d171ea207934f7356f85f9184b32d0dde69e2e0ea'
end

execute 'install nodejs' do
  command [*%w[tar -C /usr/local --no-same-owner --strip-components 1 -xJf], File.join('/var/opt/nodejs', File.basename(NODEJS_PACKAGE_ARCHIVE))]

  creates '/usr/local/bin/node'
end
