#
# Cookbook:: rpi4_server
# Recipe:: x11_config
#

operator_user = Etc.getpwnam(node['rpi4_server']&.[]('operator_user'))
operator_home = Dir.home(operator_user.name)

cookbook_file '/etc/X11/Xsession.d/10x11-disable_screensaver' do
  source '10x11-disable_screensaver'

  mode '0644'
end

cookbook_file File.join(operator_home, '.Xresources') do
  source '.Xresources'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

include_recipe 'customization::urxvt_font'
include_recipe 'customization::urxvt_transparency'
