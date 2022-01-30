#
# Cookbook:: rpi4_server
# Recipe:: dtoverlay
#
# Copyright:: 2022, The Authors, All Rights Reserved.

USERCFG_TXT                 = '/boot/firmware/usercfg.txt'

DTOVERLAY_DISABLE_BLUETOOTH = 'dtoverlay=disable-bt'
DTOVERLAY_USB_HOST          = 'dtoverlay=dwc2,dr_mode=host'
DTOVERLAY_GPIO_FAN          = Proc.new { |gpiopin:, temp:| "dtoverlay=gpio-fan,gpiopin=#{gpiopin},temp=#{temp}" }

PATTERN_DISABLE_BLUETOOTH   = /^#{Regexp.escape(DTOVERLAY_DISABLE_BLUETOOTH)}$/
PATTERN_USB_HOST            = /^#{Regexp.escape(DTOVERLAY_USB_HOST)}$/
PATTERN_GPIO_FAN            = /^#{Regexp.escape('dtoverlay=gpio-fan')}/

gpio_fan_params = node['rpi4_server']&.[]('gpio_fan')

ruby_block "Set device tree overlays in #{USERCFG_TXT}" do
  block do
    file = Chef::Util::FileEdit.new(USERCFG_TXT)

    file.insert_line_if_no_match(PATTERN_DISABLE_BLUETOOTH, DTOVERLAY_DISABLE_BLUETOOTH)
    file.insert_line_if_no_match(PATTERN_USB_HOST, DTOVERLAY_USB_HOST)

    unless gpio_fan_params.nil?
      config_line = DTOVERLAY_GPIO_FAN.call(
        gpiopin: gpio_fan_params.fetch('gpio_pin'),
        temp: gpio_fan_params.fetch('temp_millicelsius')
      )

      file.search_file_replace_line(PATTERN_GPIO_FAN, config_line)
      file.insert_line_if_no_match(PATTERN_GPIO_FAN, config_line)
    end

    file.write_file
  end
end
