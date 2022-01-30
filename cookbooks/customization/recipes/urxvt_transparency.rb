#
# Cookbook:: customization
# Recipe:: urxvt_transparency
#
# Copyright:: 2022, The Authors, All Rights Reserved.

PATTERN_URXVT_TRANSPARENT = /^URxvt\.transparent/
PATTERN_URXVT_SHADING     = /^URxvt\.shading/
PATTERN_URXVT_BLUR_RADIUS = /^URxvt\.blurRadius/

node['customization']&.[]('urxvt_transparency').each do |user, config|
  shading     = config.fetch('shading', nil)
  blur_radius = config.fetch('blurRadius', nil)

  xresources_file = File.join(Dir.home(user), '.Xresources')

  ruby_block "#{xresources_file} transparency" do
    block do
      file = Chef::Util::FileEdit.new(xresources_file)

      config_line = "URxvt.transparent: true"
      file.search_file_replace_line(PATTERN_URXVT_TRANSPARENT, config_line)
      file.insert_line_if_no_match(PATTERN_URXVT_TRANSPARENT, config_line)

      unless shading.nil?
        config_line = "URxvt.shading: #{shading}"
        file.search_file_replace_line(PATTERN_URXVT_SHADING, config_line)
        file.insert_line_if_no_match(PATTERN_URXVT_SHADING, config_line)
      end

      unless blur_radius.nil?
        config_line = "URxvt.blurRadius: #{blur_radius}"
        file.search_file_replace_line(PATTERN_URXVT_BLUR_RADIUS, config_line)
        file.insert_line_if_no_match(PATTERN_URXVT_BLUR_RADIUS, config_line)
      end

      file.write_file
    end
  end

  execute "xrdb -load #{xresources_file}" do
    command ['xrdb', '-load', xresources_file]

    user    user

    only_if { is_tty? }
  end
end
