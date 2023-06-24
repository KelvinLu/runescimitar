#
# Cookbook:: rpi4_server
# Recipe:: network
#

COMMENT_NM_ALIASES = '# NetworkManager aliases'
PATTERN_NM_ALIASES = /#{COMMENT_NM_ALIASES}$/

operator_user = Etc.getpwnam(node['rpi4_server']&.[]('operator_user'))
operator_home = Dir.home(operator_user.name)

apt_package 'network-manager' do
  action :install
end

apt_package 'iftop' do
  action :install
end

apt_package 'bmon' do
  action :install
end

cookbook_file File.join(operator_home, '.nm-aliases') do
  source 'nm-aliases'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

ruby_block 'Source .nm-aliases in .bashrc' do
  block do
    file = Chef::Util::FileEdit.new(File.join(operator_home, '.bashrc'))

    config_line = "[[ -s ~/.nm-aliases ]] && source ~/.nm-aliases #{COMMENT_NM_ALIASES}"
    file.search_file_replace_line(PATTERN_NM_ALIASES, config_line)
    file.insert_line_if_no_match(PATTERN_NM_ALIASES, config_line)

    file.write_file
  end
end

directory File.join(operator_home, '.bmon-meter') do
  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end

cookbook_file File.join(operator_home, '.config', 'systemd', 'user', 'bmon-meter.service') do
  source 'bmon-meter.service'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

cookbook_file File.join(operator_home, '.bmon-meter', 'bmon-meter') do
  source 'bmon-meter'

  owner operator_user.uid
  group operator_user.gid
  mode '0755'
end
