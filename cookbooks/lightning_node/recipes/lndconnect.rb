#
# Cookbook:: lightning_node
# Recipe:: lndconnect
#

GITHUB_LNDCONNECT_RELEASES_URL = Proc.new { |version, filename| "https://github.com/LN-Zap/lndconnect/releases/download/v#{version}/#{filename.call(version)}" }

ARCHIVE_FILENAME = Proc.new { |version| "lndconnect-linux-arm64-v#{version}.tar.gz" }

params              = node['lightning_node'].fetch('lndconnect')

lndconnect_version  = params.fetch('version')
sha256_checksums    = params.fetch('sha256_checksums')

qualified_name      = "lndconnect-linux-arm64-v#{lndconnect_version}"

directory '/var/opt/lndconnect' do
  mode '0755'
end

remote_file File.join('/var/opt/lndconnect', ARCHIVE_FILENAME.call(lndconnect_version)) do
  source GITHUB_LNDCONNECT_RELEASES_URL.call(lndconnect_version, ARCHIVE_FILENAME)

  mode '0644'

  checksum sha256_checksums.fetch('archive_targz')
end

directory 'lndconnect archive extracted directory' do
  path File.join('/var/opt/lndconnect', qualified_name)
  mode '0755'

  action :nothing
end

execute 'extract lndconnect archive' do
  command [
    'tar',
    '-xvf', File.join('/var/opt/lndconnect', ARCHIVE_FILENAME.call(lndconnect_version)),
    '-C', '/var/opt/lndconnect'
  ]

  only_if {
    extract_dir = File.join('/var/opt/lndconnect', qualified_name)
    !File.exist?(extract_dir) || Dir.empty?(extract_dir)
  }

  action :nothing

  notifies :create_if_missing, 'directory[lndconnect archive extracted directory]', :before
end

execute 'install lndconnect' do
  command lazy {
    [
      'install', '-m', '0755', '-o', 'root', '-g', 'root',
      '-t', '/usr/local/bin',
      File.join('/var/opt/lndconnect', qualified_name, 'lndconnect')
    ]
  }

  only_if { `which lndconnect`.empty? }

  notifies :run, 'execute[extract lndconnect archive]', :before
end
