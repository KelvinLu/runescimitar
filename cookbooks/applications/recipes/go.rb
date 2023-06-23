#
# Cookbook:: applications
# Recipe:: go
#

GO_PACKAGE_ARCHIVE = 'https://go.dev/dl/go1.20.5.linux-arm64.tar.gz'

directory '/var/opt/go' do
  mode '0755'
end

remote_file 'download go' do
  path File.join('/var/opt/go', File.basename(GO_PACKAGE_ARCHIVE))
  source GO_PACKAGE_ARCHIVE

  mode '0644'

  checksum 'aa2fab0a7da20213ff975fa7876a66d47b48351558d98851b87d1cfef4360d09'
end

execute 'install go' do
  command [*%w[tar -C /usr/local --no-same-owner -xzf], File.join('/var/opt/go', File.basename(GO_PACKAGE_ARCHIVE))]

  creates '/usr/local/go/bin/go'
end
