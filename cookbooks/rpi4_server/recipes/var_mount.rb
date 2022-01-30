#
# Cookbook:: rpi4_server
# Recipe:: var_mount
#
# Copyright:: 2022, The Authors, All Rights Reserved.

include_recipe 'rpi4_server::storage'

var_mount_params = node['rpi4_server']&.[]('storage')&.[]('var_mount')

unless var_mount_params.nil?
  path        = var_mount_params.fetch('path')
  marker_file = var_mount_params.fetch('marker_file')

  var_directory = File.join('/storage', path, 'var')

  directory var_directory do
    mode '0755'
  end

  ruby_block 'bind the /var mount' do
    block do
      file = Chef::Util::FileEdit.new('/etc/fstab')

      config_line = "#{var_directory} /var none bind,x-systemd.requires-mounts-for=/storage/#{path} 0 0"
      pattern     = /^#{Regexp.quote("#{var_directory} /var none bind")}/

      if File.exist?(File.join(var_directory, marker_file))
        file.search_file_replace_line(pattern, config_line)
        file.insert_line_if_no_match(pattern, config_line)
      else
        file.search_file_delete_line(pattern)
      end

      file.write_file
    end
  end

  directory '/etc/systemd/system/systemd-journal-flush.service.d' do
    mode '0755'
  end

  file '/etc/systemd/system/systemd-journal-flush.service.d/var-mount.conf' do
    content <<~CONF
    [Unit]
    PartOf=var.mount
    CONF

    mode '0644'
  end
end
