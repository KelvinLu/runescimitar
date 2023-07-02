#
# Cookbook:: rpi4_server
# Recipe:: ups_shutoff
#

params = node['rpi4_server']&.[]('ups_shutoff')

driver      = params.fetch('driver')
vendor_name = params.fetch('usb_vendor_name')
vendor_id   = params.fetch('usb_vendor_id')
product_id  = params.fetch('usb_product_id')

ups_name = "ups-#{vendor_name.downcase.gsub(/\s/, '-').delete('^a-z0-9_-')}"

unless params.nil?
  apt_package 'nut' do
    action :install
  end

  file '/etc/nut/.admin-password' do
    content lazy { `xxd -u -l 12 -p /dev/urandom`.strip.downcase }
    sensitive true

    mode '0600'

    action :create_if_missing
  end

  file '/etc/nut/.upsmon-password' do
    content lazy { `xxd -u -l 12 -p /dev/urandom`.strip.downcase }
    sensitive true

    mode '0600'

    action :create_if_missing
  end

  ruby_block 'Add entry to /etc/nut/ups.conf' do
    block do
      file = Chef::Util::FileEdit.new('/etc/nut/ups.conf')

      config = <<~CONF
        [#{ups_name}]
        driver = #{driver}
        port = auto
        desc = "Generic UPS configuration for #{vendor_name} (#{driver} driver)"
        vendorid = #{vendor_id}
        productid = #{product_id}
      CONF

      file.insert_line_if_no_match(/^#{Regexp.escape(config.lines.first.strip)}$/, config)

      file.write_file
    end
  end

  ruby_block 'Set standalone mode in /etc/nut/nut.conf' do
    block do
      file = Chef::Util::FileEdit.new('/etc/nut/nut.conf')

      file.insert_line_if_no_match(/^MODE=/, 'MODE=standalone')
      file.search_file_replace_line(/^MODE=/, 'MODE=standalone')

      file.write_file
    end
  end

  file '/etc/udev/rules.d/50-ups.rules' do
    content <<~RULES
      SUBSYSTEM=="usb", ATTR{idVendor}=="#{vendor_id}", ATTR{idProduct}=="#{product_id}", GROUP="nut"
    RULES

    mode '0644'

    notifies :run, 'execute[udevadm control reload]', :immediate
    notifies :run, 'execute[udevadm trigger]', :immediate
  end

  execute 'udevadm control reload' do
    command %w[udevadm control --reload]

    action :nothing
  end

  execute 'udevadm trigger' do
    command %w[udevadm trigger]

    action :nothing
  end

  ruby_block 'Add admin user to /etc/nut/upsd.users' do
    block do
      file = Chef::Util::FileEdit.new('/etc/nut/upsd.users')

      password = File.read('/etc/nut/.admin-password').strip

      config = <<~CONF
        [admin]
        password = #{password}
        actions = SET
        instcmds = ALL
      CONF

      file.insert_line_if_no_match(/^#{Regexp.escape(config.lines.first.strip)}$/, config)

      file.write_file
    end
  end

  ruby_block 'Add upsmon user to /etc/nut/upsd.users' do
    block do
      file = Chef::Util::FileEdit.new('/etc/nut/upsd.users')

      password = File.read('/etc/nut/.upsmon-password').strip

      config = <<~CONF
        [upsmon]
        password = #{password}
        upsmon master
      CONF

      file.insert_line_if_no_match(/^#{Regexp.escape(config.lines.first.strip)}$/, config)

      file.write_file
    end
  end

  ruby_block 'Add upsmon configuration to /etc/nut/upsmon.conf' do
    block do
      file = Chef::Util::FileEdit.new('/etc/nut/upsmon.conf')

      password = File.read('/etc/nut/.upsmon-password').strip

      config = "MONITOR #{ups_name}@localhost 1 upsmon #{password} master"

      file.insert_line_if_no_match(/^#{Regexp.escape("MONITOR #{ups_name}@localhost")}/, config)
      file.search_file_replace_line(/^#{Regexp.escape("MONITOR #{ups_name}@localhost")}/, config)

      file.write_file
    end
  end

  ruby_block 'Add NOTIFYFLAGS to /etc/nut/upsmon.conf' do
    block do
      file = Chef::Util::FileEdit.new('/etc/nut/upsmon.conf')

      %w[ONLINE ONBATT LOWBATT].each do |notify_type|
        file.insert_line_if_no_match(/^#{Regexp.escape("NOTIFYFLAG #{notify_type}")}/, "NOTIFYFLAG #{notify_type} SYSLOG+WALL")
        file.search_file_replace_line(/^#{Regexp.escape("NOTIFYFLAG #{ups_name}@localhost")}/, "NOTIFYFLAG #{notify_type} SYSLOG+WALL")
      end

      file.write_file
    end
  end
end
