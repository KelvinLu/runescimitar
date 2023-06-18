# frozen_string_literal: true

require 'json'

class Chef
  class Resource
    def local_bitcoind_listening?
      `nc -vz localhost 8332`
      $?.success?
    end
  end
end
