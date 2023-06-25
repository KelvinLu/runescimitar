#
# Cookbook:: lightning_node
# Recipe:: default
#

git_ref = node['lightning_node'].fetch('charge_lnd').fetch('git_ref')

include_recipe 'lightning_node::lnd'
include_recipe 'applications::python'

user 'charge-lnd' do
  system true
  home '/var/charge-lnd'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'lnd' do
  append true
  members %w[charge-lnd]

  action :modify
end

directory '/var/charge-lnd' do
  group lazy { Etc.getpwnam('charge-lnd').gid }
  mode '0751'
end

directory '/var/charge-lnd/macaroon' do
  group lazy { Etc.getpwnam('charge-lnd').gid }
  mode '0751'
end

file '/var/charge-lnd/macaroon/charge-lnd.macaroon' do
  user lazy { Etc.getpwnam('lnd').uid }
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0640'

  action :create_if_missing
end

execute 'generate charge-lnd macaroon' do
  command %w[
    lncli
      --macaroonpath /var/lnd/macaroon/admin.macaroon
      bakemacaroon
      --save_to /var/charge-lnd/macaroon/charge-lnd.macaroon
      offchain:read offchain:write onchain:read info:read
  ]
  user 'lnd'

  only_if { !File.exist?('/var/charge-lnd/macaroon/charge-lnd.macaroon') || File.zero?('/var/charge-lnd/macaroon/charge-lnd.macaroon') }
end

link '/var/charge-lnd/.lnd' do
  to '/var/lnd/.lnd'
end

directory '/var/opt/charge-lnd' do
  user lazy { Etc.getpwnam('charge-lnd').uid }
  group lazy { Etc.getpwnam('charge-lnd').gid }
  mode '0755'
end

git '/var/opt/charge-lnd' do
  repository 'https://github.com/accumulator/charge-lnd.git'
  revision git_ref
  depth 1

  user 'charge-lnd'

  only_if { Dir.empty?('/var/opt/charge-lnd') }
end

directory '/var/charge-lnd/.cache' do
  group lazy { Etc.getpwnam('charge-lnd').gid }
  mode '0751'
end

directory '/var/charge-lnd/.cache/pip' do
  user lazy { Etc.getpwnam('charge-lnd').uid }
  group lazy { Etc.getpwnam('charge-lnd').gid }
  mode '0751'
end

directory '/opt/charge-lnd' do
  user lazy { Etc.getpwnam('charge-lnd').uid }
  group lazy { Etc.getpwnam('charge-lnd').gid }
  mode '0755'
end

execute 'pip install charge-lnd' do
  command %w[pip3 install --user -r requirements.txt .]
  environment ({
    'USER' => 'charge-lnd',
    'HOME' => '/var/charge-lnd',
    'PYTHONUSERBASE' => '/opt/charge-lnd'

  })
  cwd '/var/opt/charge-lnd'
  user 'charge-lnd'

  timeout 7200

  creates '/opt/charge-lnd/bin/charge-lnd'
end

file '/var/charge-lnd/charge-lnd.c' do
  content <<~PROGRAM
    #include <unistd.h>

    int main(int argc, char** argv) {
      char *environment[] = {
        "PYTHONPATH=/opt/charge-lnd/lib/python#{python_version_dir}/site-packages",
        0
      };

      execve("/opt/charge-lnd/bin/charge-lnd", argv, environment);
    }
  PROGRAM

  mode '0644'
end

execute 'compile charge-lnd wrapper' do
  command %w[gcc charge-lnd.c -o /usr/local/bin/charge-lnd]
  cwd '/var/charge-lnd'

  creates '/usr/local/bin/charge-lnd'
end
