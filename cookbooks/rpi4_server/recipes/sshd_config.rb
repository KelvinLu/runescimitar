#
# Cookbook:: rpi4_server
# Recipe:: sshd_config
#
# Copyright:: 2022, The Authors, All Rights Reserved.

allow_users = [*node['rpi4_server']&.[]('ssh_allow_users')]
deny_users = [*node['rpi4_server']&.[]('ssh_deny_users')]

ruby_block 'configure /etc/ssh/sshd_config' do
  block do
    file = Chef::Util::FileEdit.new('/etc/ssh/sshd_config')

    config_line = 'PasswordAuthentication no'
    file.search_file_replace_line(/^PasswordAuthentication/, config_line)
    file.insert_line_if_no_match(/^PasswordAuthentication/, config_line)

    config_line = 'ChallengeResponseAuthentication no'
    file.search_file_replace_line(/^ChallengeResponseAuthentication/, config_line)
    file.insert_line_if_no_match(/^ChallengeResponseAuthentication/, config_line)

    config_line = 'KbdInteractiveAuthentication no'
    file.search_file_replace_line(/^KbdInteractiveAuthentication/, config_line)
    file.insert_line_if_no_match(/^KbdInteractiveAuthentication/, config_line)

    config_line = 'PermitRootLogin no'
    file.search_file_replace_line(/^PermitRootLogin/, config_line)
    file.insert_line_if_no_match(/^PermitRootLogin/, config_line)

    unless allow_users.empty?
      config_line = "AllowUsers #{allow_users.join(' ')}"
      file.search_file_replace_line(/^AllowUsers/, config_line)
      file.insert_line_if_no_match(/^AllowUsers/, config_line)
    end

    unless deny_users.empty?
      config_line = "DenyUsers #{deny_users.join(' ')}"
      file.search_file_replace_line(/^DenyUsers/, config_line)
      file.insert_line_if_no_match(/^DenyUsers/, config_line)
    end

    config_line = 'Subsystem sftp internal-sftp'
    file.search_file_replace_line(/^Subsystem\s+sftp/, config_line)
    file.insert_line_if_no_match(/^Subsystem\s+sftp/, config_line)

    file.write_file
  end
end
