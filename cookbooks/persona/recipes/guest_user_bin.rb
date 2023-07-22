#
# Cookbook:: persona
# Recipe:: guest_user_bin
#

root_location = node['persona'].fetch('root_location', '/home')
params        = node['persona'].fetch('guest_user')
username      = params.fetch('name')

home_bin_dir = File.join(root_location, username, 'home/', username, '.bin')

directory home_bin_dir do
  group lazy { Etc.getpwnam(username).gid }
  mode '0755'
end

{
  ls: '/usr/bin/ls',
  mv: '/usr/bin/mv',
  cp: '/usr/bin/cp',
  rm: '/usr/bin/rm',
  mkdir: '/usr/bin/mkdir',
  rmdir: '/usr/bin/rmdir',
  mount: '/usr/bin/mount',
  umount: '/usr/bin/umount',

  cat: '/usr/bin/cat',
  tee: '/usr/bin/tee',
  head: '/usr/bin/head',
  tail: '/usr/bin/tail',
  cut: '/usr/bin/cut',
  tr: '/usr/bin/tr',

  rvim: '/usr/bin/rvim',
  rview: '/usr/bin/rview',

  'feh-viewer': '/opt/feh-viewer/bin/feh-viewer',

  grep: '/usr/bin/grep',
  wc: '/usr/bin/wc',
  sort: '/usr/bin/sort',
  uniq: '/usr/bin/uniq',

  xxd: '/usr/bin/xxd',

  printf: '/usr/bin/printf',
  bc: '/usr/bin/bc',

  shasum: '/usr/bin/shasum',
  sha256sum: '/usr/bin/sha256sum',

  bx: '/usr/local/bin/bx',

  'sparrow-terminal': '/opt/sparrow-server/bin/Sparrow',
}.each do |symlink, path|
  link File.join(home_bin_dir, symlink.to_s) do
    to path

    only_if { File.exist?(path) }
  end
end
