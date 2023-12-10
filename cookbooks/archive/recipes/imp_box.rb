#
# Cookbook:: archive
# Recipe:: imp_box
#

git_ref = node['archive'].fetch('imp_box').fetch('git_ref')

directory '/opt/imp-box' do
  mode '0755'
end

git '/opt/imp-box' do
  repository 'https://github.com/KelvinLu/imp-box.git'
  revision git_ref
  depth 1

  only_if { Dir.empty?('/opt/imp-box') }
end
