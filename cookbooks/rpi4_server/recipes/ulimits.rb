#
# Cookbook:: rpi4_server
# Recipe:: ulimits
#
# Copyright:: 2022, The Authors, All Rights Reserved.

user_ulimit '*' do
  filehandle_soft_limit 65_536
  filehandle_hard_limit 524_288

  process_soft_limit    8_192
  process_hard_limit    32_768
end

PATTERN_PAM_LIMITS = /pam_limits\.so$/

ruby_block 'Append pam_limits.so module' do
  block do
    file_common_session =
      Chef::Util::FileEdit.new('/etc/pam.d/common-session')
    file_common_session_noninteractive =
      Chef::Util::FileEdit.new('/etc/pam.d/common-session-noninteractive')

    config_line = 'session required                        pam_limits.so'
    file_common_session.search_file_replace_line(PATTERN_PAM_LIMITS, config_line)
    file_common_session.insert_line_if_no_match(PATTERN_PAM_LIMITS, config_line)
    file_common_session_noninteractive.search_file_replace_line(PATTERN_PAM_LIMITS, config_line)
    file_common_session_noninteractive.insert_line_if_no_match(PATTERN_PAM_LIMITS, config_line)

    file_common_session.write_file
    file_common_session_noninteractive.write_file
  end
end
