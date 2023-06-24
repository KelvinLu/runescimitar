#
# Cookbook:: applications
# Recipe:: cpp_build_tools
#

apt_package 'g++-9' do
  action :install
end

apt_package 'clang-11' do
  action :install
end

apt_package 'build-essential' do
  action :install
end

apt_package 'autoconf' do
  action :install
end

apt_package 'automake' do
  action :install
end

apt_package 'libtool' do
  action :install
end

apt_package 'pkg-config' do
  action :install
end

