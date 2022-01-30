#
# Cookbook:: rpi4_server
# Recipe:: etc_bashrc
#
# Copyright:: 2022, The Authors, All Rights Reserved.

COMMENT_PS1_PROMPT = '# PS1 prompt'
PATTERN_PS1_PROMPT = /#{COMMENT_PS1_PROMPT}$/

COMMENT_SET_TTY_FONT = '# Set TTY font'
PATTERN_SET_TTY_FONT = /#{COMMENT_SET_TTY_FONT}$/

FONT_FILE = '/usr/share/consolefonts/UbuntuMono-R-8x16.psf'

cookbook_file File.join('/etc/ps1') do
  source 'ps1'

  mode '0644'
end

ruby_block 'Add PS1 script to .bashrc' do
  block do
    file = Chef::Util::FileEdit.new('/etc/bash.bashrc')

    config_line = "[[ -s /etc/ps1 ]] && source /etc/ps1 #{COMMENT_PS1_PROMPT}"
    file.search_file_replace_line(PATTERN_PS1_PROMPT, config_line)
    file.insert_line_if_no_match(PATTERN_PS1_PROMPT, config_line)

    file.write_file
  end
end

ruby_block 'Set TTY font in .bashrc' do
  block do
    file = Chef::Util::FileEdit.new('/etc/bash.bashrc')

    config_line = "[[ $(tty) == /dev/tty* && -f '#{FONT_FILE}' ]] && setfont '#{FONT_FILE}' #{COMMENT_SET_TTY_FONT}"
    file.search_file_replace_line(PATTERN_SET_TTY_FONT, config_line)
    file.insert_line_if_no_match(PATTERN_SET_TTY_FONT, config_line)

    file.write_file
  end
end
