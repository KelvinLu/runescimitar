#
# Cookbook:: lightning_node
# Recipe:: personal_user_lndconnect
#

params   = node['bitcoin_users'].fetch('personal_user')
username = params.fetch('name')

file File.join(Dir.home(username), 'lndconnect-admin') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    lndconnect --adminmacaroonpath /var/lnd/macaroon/admin.macaroon "$@"
  BASH
end

file File.join(Dir.home(username), 'lndconnect-readonly') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    lndconnect --readonlymacaroonpath /var/lnd/macaroon/readonly.macaroon --readonly "$@"
  BASH
end

file File.join(Dir.home(username), 'lndconnect-invoice') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    lndconnect --invoicemacaroonpath /var/lnd/macaroon/invoice.macaroon --invoice "$@"
  BASH
end

execute 'lndconnect-qr.png placeholder pipe' do
  command %w[mkfifo -m0600 lndconnect-qr.png]

  cwd Dir.home(username)

  creates File.join(Dir.home(username), 'lndconnect-qr.png')
end

execute 'lndconnect-qr.png ownership' do
  command ['chown', "#{username}:#{username}", File.join(Dir.home(username), 'lndconnect-qr.png')]
end

file File.join(Dir.home(username), 'lndconnect-view-qr') do
  group lazy { Etc.getpwnam(username).gid }
  mode '0750'

  content <<~BASH
    #!/bin/bash
    feh-viewer < lndconnect-qr.png
  BASH
end
