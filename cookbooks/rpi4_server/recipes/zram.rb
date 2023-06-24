#
# Cookbook:: rpi4_server
# Recipe:: zram
#

swap_params = node['rpi4_server']&.[]('zram_swap')
devices = swap_params['devices']
size_mb = swap_params['uncompressed_limit_mb']

apt_package 'zram-tools' do
  action :install
end

ruby_block 'configure /etc/default/zramswap' do
  block do
    file = Chef::Util::FileEdit.new('/etc/default/zramswap')

    config_line = "CORES=#{devices}"
    file.search_file_replace_line(/^CORES=\d+$/, config_line)
    file.insert_line_if_no_match(/^CORES=\d+$/, config_line)

    config_line = "ALLOCATION=#{size_mb}"
    file.search_file_replace_line(/^ALLOCATION=\d+$/, config_line)
    file.insert_line_if_no_match(/^ALLOCATION=\d+$/, config_line)

    file.write_file
  end
end

sysctl 'vm.vfs_cache_pressure' do
  value 500
end

sysctl 'vm.swappiness' do
  value 100
end

sysctl 'vm.dirty_background_ratio' do
  value 1
end

sysctl 'vm.dirty_ratio' do
  value 50
end
