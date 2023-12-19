#
# Cookbook:: rpi4_server
# Recipe:: tailscale
#

TOR_PROJECT_GPG_KEY_URL = Proc.new { |release_codename| "https://pkgs.tailscale.com/stable/ubuntu/#{release_codename}.noarmor.gpg" }
SHA256_DIGEST_KEY = '3e03dacf222698c60b8e2f990b809ca1b3e104de127767864284e6c228f1fb39'

lsb_release_codename = `lsb_release -c`.strip.delete_prefix("Codename:\t")

include_recipe 'rpi4_server::vpn'

remote_file '/usr/share/keyrings/tailscale-archive-keyring.gpg' do
  source TOR_PROJECT_GPG_KEY_URL.call(lsb_release_codename)

  mode '0644'

  checksum SHA256_DIGEST_KEY
end

file '/etc/apt/sources.list.d/tailscale.list' do
  content <<~SOURCE_LIST
    deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu #{lsb_release_codename} main
  SOURCE_LIST

  notifies :run, 'execute[apt update]', :immediate
end

execute 'apt update' do
  command %w[apt update]

  action :nothing
end

apt_package 'tailscale' do
  action :install
end
