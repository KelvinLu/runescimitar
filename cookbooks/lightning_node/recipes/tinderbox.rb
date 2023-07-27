#
# Cookbook:: lightning_node
# Recipe:: tinderbox
#

git_ref = node['lightning_node'].fetch('tinderbox').fetch('git_ref')

directory '/opt/tinderbox' do
  mode '0755'
end

git '/opt/tinderbox' do
  repository 'https://github.com/KelvinLu/tinderbox.git'
  revision git_ref
  depth 1

  only_if { Dir.empty?('/opt/tinderbox') }
end

file '/opt/tinderbox/tinderbox-wrapper.c' do
  content <<~PROGRAM
    #include <unistd.h>

    int main(int argc, char** argv) {
      execv("/opt/tinderbox/bin/tinderbox", argv);
    }
  PROGRAM

  mode '0644'
end

execute 'compile tinderbox wrapper' do
  command %w[gcc tinderbox-wrapper.c -o /usr/local/bin/tinderbox]
  cwd '/opt/tinderbox'

  creates '/usr/local/bin/tinderbox'
end
