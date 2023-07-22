#
# Cookbook:: applications
# Recipe:: feh_viewer
#

include_recipe 'applications::feh'

directory '/opt/feh-viewer' do
  mode '0755'
end

directory '/opt/feh-viewer/bin' do
  mode '0755'
end

file '/opt/feh-viewer/feh-viewer.c' do
  content <<~PROGRAM
    #include <unistd.h>

    int main(int argc, char** argv) {
      if (argc != 1) return 2;

      char *arguments[] = {
        argv[0],
        "--no-menu",
        "-",
        0
      };

      execv("/usr/bin/feh", arguments);
    }
  PROGRAM

  mode '0644'
end

execute 'compile feh-viewer wrapper' do
  command %w[gcc feh-viewer.c -o /opt/feh-viewer/bin/feh-viewer]
  cwd '/opt/feh-viewer'

  creates '/opt/feh-viewer/bin/feh-viewer'
end
