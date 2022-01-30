# frozen_string_literal: true

class Chef
  class Resource
    def is_tty?
      `tty`.start_with?('/dev/tty')
    end
  end
end
