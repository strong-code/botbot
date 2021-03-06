#!/usr/bin/env ruby

require 'singleton'
require 'optparse'
require_relative './lib/db/database.rb'
Dir[File.join(".", "lib/*.rb")].each { |f| require f }

class Bot
  include BotLogger, Irc, ShitList

  def initialize(chan = nil)
    chan = ARGV[0]
    init_irc(chan)
    init_bot_logger()
    Database.init_db()
  end

  # Open a TCPSocket and connect, joining the channel when appropriate.
  def run
    load_triggers()
    @socket = TCPSocket.open(@server, @port)

    $log.info("Initiating handshake with server...")
    say "USER #{@nick} 0 * #{@nick}"
    say "NICK #{@nick}"

    until @socket.eof? do
      msg = @socket.gets
      msg = (msg.split(" ")[1] == "PRIVMSG" ? PrivateMessage.new(msg) : Message.new(msg))

      if msg.class == PrivateMessage
        store_message(msg)
        # temporary
        Database.store_quote(msg)
        Markov.analyze(msg.text)
        fire_triggers(msg) unless is_banned?(msg.nickname)
      else
        respond_to_server(msg)
      end

      $log.info("#{msg.stringify}")
    end
  end

end

$bot = Bot.new()
$bot.run()
