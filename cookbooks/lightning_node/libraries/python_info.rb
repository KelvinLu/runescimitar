# frozen_string_literal: true

require 'json'

class Chef
  class Resource
    def python_version
      `python3 -c 'import platform; print(platform.python_version())'`.strip
    end

    def python_version_dir
      python_version.split('.')[0..1].join('.')
    end
  end
end
