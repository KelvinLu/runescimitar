#
# Cookbook:: lightning_node
# Recipe:: scrying_orb
#

git_ref = node['lightning_node'].fetch('scrying_orb').fetch('git_ref')

directory '/opt/scrying-orb' do
  mode '0755'
end

git '/opt/scrying-orb' do
  repository 'https://github.com/KelvinLu/scrying-orb.git'
  revision git_ref
  depth 1

  only_if { Dir.empty?('/opt/scrying-orb') }
end

file '/opt/scrying-orb/scrying-orb-wrapper.c' do
  content <<~PROGRAM
    #include <unistd.h>

    int main(int argc, char** argv) {
      execv("/opt/scrying-orb/bin/scrying-orb", argv);
    }
  PROGRAM

  mode '0644'
end

execute 'compile scrying-orb wrapper' do
  command %w[gcc scrying-orb-wrapper.c -o /usr/local/bin/scrying-orb]
  cwd '/opt/scrying-orb'

  creates '/usr/local/bin/scrying-orb'
end
