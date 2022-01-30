#
# Cookbook:: rpi4_server
# Recipe:: cmdline
#
# Copyright:: 2022, The Authors, All Rights Reserved.

CMDLINE_TXT         = '/boot/firmware/cmdline.txt'

SCREENSAVER_NOBLANK = 'consoleblank=0'

ruby_block "Set Linux cmdline (#{CMDLINE_TXT})" do
  block do
    parameters = File.read(CMDLINE_TXT).split

    parameters.append(SCREENSAVER_NOBLANK) unless parameters.include?(SCREENSAVER_NOBLANK)

    File.write(CMDLINE_TXT, parameters.join(' '))
  end
end
