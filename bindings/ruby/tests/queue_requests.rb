#
# Do parallel identify requests using the same client instance via celluloid gem
#
# Tests https://github.com/Openwsman/openwsman/issues/10
#
# Written by kkaempf@suse.de
#
require 'openwsman'
require 'celluloid'
require 'open-uri'

class Identify
  include Celluloid

  def identify(client, timeout = nil)
    puts "Identify #{client}"
    #Openwsman::debug = 9
    client.transport.verify_peer = 0
    options = Openwsman::ClientOptions.new
    if timeout
      options.flags = Openwsman::FLAG_QUEUE_REQUEST
      if timeout > 0
        options.queue_timeout = timeout
      end
    end

    request(client, options) do |response|
      puts "#{client} identify #{response}"
    end
  end

  private
  def request(client, options, &response_handler_block)
    response = client.identify(options)
    if response
      response_handler_block.call(response)
    else
      puts "#{client} FAILED"
    end
  end
end

SLOTS = 10

identifiers = Identify.pool(size: SLOTS)

client = Openwsman::Client.new("localhost", 5985, "/wsman", "http", 'wsman', 'secret')
(1..SLOTS).each do
  identifiers.async.identify(client, 10)
end

sleep
