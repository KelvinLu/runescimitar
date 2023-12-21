#
# Cookbook:: applications
# Recipe:: gatus
#

git_ref = node['applications'].fetch('gatus').fetch('git_ref')

include_recipe 'rpi4_server::ufw'
include_recipe 'applications::go'

user 'gatus' do
  system true
  home '/var/gatus'
  shell '/usr/sbin/nologin'

  manage_home false
end

directory '/var/gatus' do
  group lazy { Etc.getpwnam('gatus').gid }
  mode '0751'
end

directory '/var/gatus/go' do
  user lazy { Etc.getpwnam('gatus').uid }
  group lazy { Etc.getpwnam('gatus').gid }
  mode '0751'
end

directory '/var/gatus/.cache' do
  user lazy { Etc.getpwnam('gatus').uid }
  group lazy { Etc.getpwnam('gatus').gid }
  mode '0751'
end

directory '/var/opt/gatus' do
  user lazy { Etc.getpwnam('gatus').uid }
  group lazy { Etc.getpwnam('gatus').gid }
  mode '0755'
end

directory '/etc/gatus' do
  group lazy { Etc.getpwnam('gatus').gid }
  mode '0751'
end

directory '/etc/gatus/config' do
  group lazy { Etc.getpwnam('gatus').gid }
  mode '0751'
end

git '/var/opt/gatus' do
  repository 'https://github.com/TwiN/gatus.git'
  revision git_ref
  depth 1

  user 'gatus'

  only_if { Dir.empty?('/var/opt/gatus') }
end

execute 'go install gatus' do
  command %w[go install]
  environment ({
    'USER' => 'gatus',
    'HOME' => '/var/gatus',
    'PATH' => '/usr/local/go/bin',
    'GOPATH' => '/var/gatus/go',
  })
  cwd '/var/opt/gatus'
  user 'gatus'

  creates '/var/gatus/go/bin/gatus'
end

directory '/opt/gatus' do
  mode '0755'
end

directory '/opt/gatus/bin' do
  mode '0755'
end

execute 'install gatus' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/opt/gatus/bin',
      '/var/gatus/go/bin/gatus'
    ]
  }

  not_if { File.exist?('/opt/gatus/bin/gatus') }
end

file '/etc/gatus/config/config.yaml' do
  content <<~YAML
  # Empty configuration -- edit this.
  ---
  {}
  YAML

  group lazy { Etc.getpwnam('gatus').gid }
  mode '0640'

  action :create_if_missing
end

execute 'ufw allow gatus connection' do
  command [*%w[ufw allow 8080/tcp comment], 'Allow Gatus']

  not_if do
    `ufw status verbose | grep -q '8080/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

cookbook_file '/etc/systemd/system/gatus.service' do
  source 'gatus.service'

  mode '0644'
end

systemd_unit 'gatus.service' do
  action :enable
end
