#
# Cookbook:: rpi4_server
# Recipe:: nginx
#
# Copyright:: 2022, The Authors, All Rights Reserved.

server_name   = node['name'] || 'localhost'
file_basename = "#{server_name}_self-signed"

apt_package 'nginx' do
  action :install
end

execute 'self-signed server certificate for nginx' do
  command %W[
    openssl req -x509 -newkey rsa:4096 -nodes
      -keyout /etc/ssl/private/#{file_basename}.key
      -out /etc/ssl/certs/#{file_basename}.cert
      -subj /CN=#{server_name}
      -days 730
  ]

  creates "/etc/ssl/certs/#{file_basename}.cert"
end

user 'nginx' do
  system true
  home '/var/nginx'
  shell '/usr/sbin/nologin'

  manage_home false
end

directory '/var/nginx' do
  group lazy { Etc.getpwnam('nginx').gid }
  mode '0755'
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'

  variables(file_basename: file_basename)

  mode '0644'
end

directory '/etc/nginx/streams-enabled' do
  group lazy { Etc.getpwnam('nginx').gid }
  mode '0755'
end

execute 'nginx test configuration' do
  command %w[nginx -t]

  action :nothing
end

systemd_unit 'nginx.service' do
  action :nothing
end
