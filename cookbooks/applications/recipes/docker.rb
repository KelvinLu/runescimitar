#
# Cookbook:: applications
# Recipe:: docker
#

DOCKER_GPG_KEY_URL = 'https://download.docker.com/linux/ubuntu/gpg'
SHA256_DIGEST_KEY = '1500c1f56fa9e26b9b8f42452a553675796ade0807cdce11975eb98170b3a570'

lsb_release_codename = `lsb_release -c`.strip.delete_prefix("Codename:\t")

alternate_storage_location = node['applications']&.[]('docker')&.[]('storage_location')
rootless_mode = node['applications']&.[]('docker')&.[]('rootless') || false

user 'docker' do
  home '/var/docker'
  shell '/usr/bin/bash'

  manage_home false
end

execute 'loginctl enable-linger docker' do
  command %w[loginctl enable-linger docker]
end

directory '/var/docker' do
  user lazy { Etc.getpwnam('docker').uid }
  group lazy { Etc.getpwnam('docker').gid }
  mode '0751'
end

cookbook_file '/var/docker/.inputrc' do
  source 'docker.inputrc'

  mode '0644'
end

cookbook_file '/var/docker/.bashrc' do
  source 'docker.bashrc'

  mode '0644'
end

directory '/var/docker/.docker' do
  user lazy { Etc.getpwnam('docker').uid }
  group lazy { Etc.getpwnam('docker').gid }
  mode '0755'

  only_if { rootless_mode }
end

directory '/var/docker/.docker/run' do
  user lazy { Etc.getpwnam('docker').uid }
  group lazy { Etc.getpwnam('docker').gid }
  mode '0755'

  only_if { rootless_mode }
end

link 'link docker socket' do
  target_file '/var/docker/.docker/run/docker.sock'
  to lazy { "/run/user/#{Etc.getpwnam('docker').uid}/docker.sock" }

  only_if { rootless_mode }
end

directory '/var/docker/.config' do
  group lazy { Etc.getpwnam('docker').gid }
  mode '0755'
end

directory '/var/docker/.config/systemd' do
  group lazy { Etc.getpwnam('docker').gid }
  mode '0755'
end

directory '/var/docker/.config/systemd/user' do
  group lazy { Etc.getpwnam('docker').gid }
  mode '0755'
end

cookbook_file '/var/docker/.config/systemd/user/docker.service' do
  source 'docker_rootless.service'

  group lazy { Etc.getpwnam('docker').gid }
  mode '0755'

  only_if { rootless_mode }
end

unless alternate_storage_location.nil?
  directory '/var/docker/.local' do
    user lazy { Etc.getpwnam('docker').uid }
    group lazy { Etc.getpwnam('docker').gid }
    mode '0711'

    only_if { rootless_mode }
  end

  directory '/var/docker/.local/share' do
    user lazy { Etc.getpwnam('docker').uid }
    group lazy { Etc.getpwnam('docker').gid }
    mode '0711'

    only_if { rootless_mode }
  end

  directory File.join(alternate_storage_location, 'docker') do
    user lazy { Etc.getpwnam('docker').uid }
    group lazy { Etc.getpwnam('docker').gid }
    mode '0710'
  end

  link 'docker data root' do
    target_file lazy {
      rootless_mode ? '/var/docker/.local/share/docker' : '/var/lib/docker'
    }
    to File.join(alternate_storage_location, 'docker')
  end
end

remote_file 'docker gpg key' do
  path '/usr/share/keyrings/docker.asc'
  source DOCKER_GPG_KEY_URL

  mode '0644'

  checksum SHA256_DIGEST_KEY
end

execute 'remove ascii armor encoding from key and place into /etc/apt/keyrings/docker.gpg' do
  command %w[gpg --batch --no-tty -o /etc/apt/keyrings/docker.gpg --dearmor /usr/share/keyrings/docker.asc]

  creates '/etc/apt/keyrings/docker.gpg'
end

file '/etc/apt/sources.list.d/docker.list' do
  content <<~SOURCE_LIST
    deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu #{lsb_release_codename} stable
  SOURCE_LIST

  notifies :run, 'execute[apt update]', :immediate
end

execute 'apt update' do
  command %w[apt update]

  action :nothing
end

apt_package 'docker-ce' do
  action :install
end

apt_package 'docker-ce-cli' do
  action :install
end

apt_package 'containerd.io' do
  action :install
end

apt_package 'docker-compose-plugin' do
  action :install
end

apt_package 'uidmap' do
  action :install

  only_if { rootless_mode }
end

systemd_unit 'docker.service' do
  action (rootless_mode ? :disable : :enable)
end

systemd_unit 'docker.socket' do
  action (rootless_mode ? :disable : :enable)
end

execute 'docker rootless install' do
  command %w[dockerd-rootless-setuptool.sh install]
  environment ({ 'HOME' => '/var/docker/', 'USER' => 'docker' })
  cwd '/var/docker'

  user 'docker'

  creates '/var/docker/.skip-install-chef'

  only_if { rootless_mode }
end

file '/var/docker/.skip-install-chef' do
  action :create_if_missing

  only_if { rootless_mode }
end

execute 'systemctl --user enable docker.service' do
  command %w[systemctl --user --machine docker@.host enable docker.service]

  only_if { rootless_mode }
end
