#
# Cookbook:: customization
# Recipe:: urxvt_font
#
# Copyright:: 2022, The Authors, All Rights Reserved.

DEFAULT_FONT_SIZE = 12

PATTERN_URXVT_FONT      = /^URxvt\.font/
PATTERN_URXVT_FONT_BOLD = /^URxvt\.boldFont/

node['customization']&.[]('urxvt_font').each do |user, config|
  font_name   = config.fetch('font')
  font_size   = config.fetch('font_size', DEFAULT_FONT_SIZE)
  recipe_name = config.fetch('include_recipe', nil)

  include_recipe(recipe_name) unless recipe_name.nil?

  xresources_file = File.join(Dir.home(user), '.Xresources')

  execute "fc-list #{font_name}" do
    command ['fc-list', '-q', font_name]

    user    user
  end

  ruby_block "#{xresources_file} #{font_name}" do
    block do
      file = Chef::Util::FileEdit.new(xresources_file)

      config_line = "URxvt.font: xft:#{font_name}:size=#{font_size}"
      file.search_file_replace_line(PATTERN_URXVT_FONT, config_line)
      file.insert_line_if_no_match(PATTERN_URXVT_FONT, config_line)

      if `fc-list '#{font_name}' style`.lines.map(&:strip).include?(':style=Bold')
        config_line = "URxvt.boldFont: xft:#{font_name}:bold:size=#{font_size}"
        file.search_file_replace_line(PATTERN_URXVT_FONT_BOLD, config_line)
        file.insert_line_if_no_match(PATTERN_URXVT_FONT_BOLD, config_line)
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
