#
# Cookbook:: rpi4_server
# Recipe:: swap_space
#

include_recipe 'rpi4_server::storage'

swap_params = node['rpi4_server']&.[]('swap')
swap_file_path = swap_params['file']

unless swap_file_path.nil?
  swap_file swap_file_path do
    size    swap_params.fetch('size_mb')
    persist true

    only_if do
      device_uuid = swap_params['device']
      device_uuid.nil? || (get_device_uuid(File.dirname(swap_file_path)) == device_uuid)
    end
  end
end
