#
# Cookbook:: lightning_node
# Recipe:: default
#

git_ref = node['lightning_node'].fetch('rebalance_lnd').fetch('git_ref')

include_recipe 'lightning_node::lnd'
include_recipe 'applications::python'

user 'rebalance-lnd' do
  system true
  home '/var/rebalance-lnd'
  shell '/usr/sbin/nologin'

  manage_home false
end

group 'lnd' do
  append true
  members %w[rebalance-lnd]

  action :modify
end

directory '/var/rebalance-lnd' do
  group lazy { Etc.getpwnam('rebalance-lnd').gid }
  mode '0751'
end

directory '/var/rebalance-lnd/.lnd' do
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

directory '/var/rebalance-lnd/.lnd/data' do
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

directory '/var/rebalance-lnd/.lnd/data/chain' do
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

directory '/var/rebalance-lnd/.lnd/data/chain/bitcoin' do
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

directory '/var/rebalance-lnd/.lnd/data/chain/bitcoin/mainnet' do
  group lazy { Etc.getpwnam('lnd').gid }
  mode '0751'
end

link '/var/rebalance-lnd/.lnd/tls.cert' do
  to '/var/lnd/.lnd/tls.cert'
end

link '/var/rebalance-lnd/.lnd/data/chain/bitcoin/mainnet/admin.macaroon' do
  to '/var/lnd/macaroon/admin.macaroon'
end

directory '/var/opt/rebalance-lnd' do
  user lazy { Etc.getpwnam('rebalance-lnd').uid }
  group lazy { Etc.getpwnam('rebalance-lnd').gid }
  mode '0755'
end

git '/var/opt/rebalance-lnd' do
  repository 'https://github.com/C-Otto/rebalance-lnd.git'
  revision git_ref
  depth 1

  user 'rebalance-lnd'

  only_if { Dir.empty?('/var/opt/rebalance-lnd') }
end

directory '/var/rebalance-lnd/.cache' do
  group lazy { Etc.getpwnam('rebalance-lnd').gid }
  mode '0751'
end

directory '/var/rebalance-lnd/.cache/pip' do
  user lazy { Etc.getpwnam('rebalance-lnd').uid }
  group lazy { Etc.getpwnam('rebalance-lnd').gid }
  mode '0751'
end

directory '/opt/rebalance-lnd' do
  user lazy { Etc.getpwnam('rebalance-lnd').uid }
  group lazy { Etc.getpwnam('rebalance-lnd').gid }
  mode '0755'
end

execute 'pip install rebalance-lnd' do
  command %w[pip3 install --user -r requirements.txt]
  environment ({
    'USER' => 'rebalance-lnd',
    'HOME' => '/var/rebalance-lnd',
    'PYTHONUSERBASE' => '/opt/rebalance-lnd'

  })
  cwd '/var/opt/rebalance-lnd'
  user 'rebalance-lnd'

  timeout 7200

  creates '/opt/rebalance-lnd/lib'
end

directory '/opt/rebalance-lnd/bin' do
  user lazy { Etc.getpwnam('rebalance-lnd').uid }
  group lazy { Etc.getpwnam('rebalance-lnd').gid }
  mode '0755'
end

execute 'install rebalance.py script' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/opt/rebalance-lnd/bin',
      '/var/opt/rebalance-lnd/rebalance.py'
    ]
  }

  not_if { File.exist?('/opt/rebalance-lnd/bin/rebalance.py') }
end

file '/var/rebalance-lnd/rebalance-lnd.c' do
  content <<~PROGRAM
    #include <unistd.h>

    int main(int argc, char** argv) {
      char *environment[] = {
        "PYTHONPATH=/var/opt/rebalance-lnd:/opt/rebalance-lnd/lib/python#{python_version_dir}/site-packages",
        0
      };

      execve("/opt/rebalance-lnd/bin/rebalance.py", argv, environment);
    }
  PROGRAM

  mode '0644'
end

execute 'compile rebalance-lnd wrapper' do
  command %w[gcc rebalance-lnd.c -o /usr/local/bin/rebalance-lnd]
  cwd '/var/rebalance-lnd'

  creates '/usr/local/bin/rebalance-lnd'
end
