#
# Cookbook:: lightning_node
# Recipe:: circuit_breaker
#

git_ref = node['lightning_node'].fetch('circuit_breaker').fetch('git_ref')

include_recipe 'lightning_node::lnd'
include_recipe 'applications::go'

user 'circuitbreaker' do
  system true
  home '/var/circuitbreaker'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'lnd' do
  append true
  members %w[circuitbreaker]

  action :modify
end

directory '/var/circuitbreaker' do
  group lazy { Etc.getpwnam('circuitbreaker').gid }
  mode '0751'
end

link '/var/circuitbreaker/.lnd' do
  to '/var/lnd/.lnd'
end

directory '/var/circuitbreaker/go' do
  user lazy { Etc.getpwnam('circuitbreaker').uid }
  group lazy { Etc.getpwnam('circuitbreaker').gid }
  mode '0751'
end

directory '/var/circuitbreaker/.cache' do
  user lazy { Etc.getpwnam('circuitbreaker').uid }
  group lazy { Etc.getpwnam('circuitbreaker').gid }
  mode '0751'
end

directory '/var/opt/circuitbreaker' do
  user lazy { Etc.getpwnam('circuitbreaker').uid }
  group lazy { Etc.getpwnam('circuitbreaker').gid }
  mode '0755'
end

git '/var/opt/circuitbreaker' do
  repository 'https://github.com/lightningequipment/circuitbreaker.git'
  revision git_ref
  depth 1

  user 'circuitbreaker'

  only_if { Dir.empty?('/var/opt/circuitbreaker') }
end

execute 'go install circuitbreaker' do
  command %w[go install]
  environment ({
    'USER' => 'circuitbreaker',
    'HOME' => '/var/circuitbreaker',
    'PATH' => '/usr/local/go/bin',
    'GOPATH' => '/var/circuitbreaker/go',
  })
  cwd '/var/opt/circuitbreaker'
  user 'circuitbreaker'

  creates '/var/circuitbreaker/go/bin/circuitbreaker'
end

directory '/opt/circuitbreaker' do
  mode '0755'
end

directory '/opt/circuitbreaker/bin' do
  mode '0755'
end

execute 'install circuitbreaker' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/opt/circuitbreaker/bin',
      '/var/circuitbreaker/go/bin/circuitbreaker'
    ]
  }

  not_if { File.exist?('/opt/circuitbreaker/bin/circuitbreaker') }
end

directory '/var/circuitbreaker/.circuitbreaker' do
  user lazy { Etc.getpwnam('circuitbreaker').uid }
  group lazy { Etc.getpwnam('circuitbreaker').gid }
  mode '0751'
end

cookbook_file '/etc/systemd/system/circuitbreaker.service' do
  source 'circuitbreaker.service'

  mode '0644'
end

systemd_unit 'circuitbreaker.service' do
  action :enable
end
