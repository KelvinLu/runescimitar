# frozen_string_literal: true

require 'json'

class Chef
  class Resource
    def bitcoin_cli_on_path?
      !`which bitcoin-cli`.strip.empty?
    end

    def local_bitcoind_listening?
      `nc -vz localhost 8332`
      $?.success?
    end

    def currently_doing_initial_block_download?
      return nil unless bitcoin_cli_on_path? && local_bitcoind_listening?

      JSON.parse(`bitcoin-cli -datadir=/var/bitcoin/datadir getblockchaininfo`).fetch('initialblockdownload')
    end
  end
end
