# frozen_string_literal: true

class Chef
  class Resource
    def get_mount_point(file)
      `df --output=target '#{file}'`.lines.last.strip
    end

    def get_device_uuid(file)
      dir = `df --output=source '#{file}'`.lines.last.strip
      `lsblk --noheadings --output uuid '#{dir}'`.strip
    end
  end
end
