require "neovim"
require "neovim/connection"
require "neovim/event_loop"
require "neovim/executable"
require "neovim/session"
require "neovim/ui/event"
require "io/console"
require "thread"

module Neovim
  class UI
    attr_reader :dimensions, :handlers

    def initialize(dimensions, handlers, session_yielder, input_yielder)
      @dimensions = dimensions
      @handlers = handlers
      @session_yielder = session_yielder
      @input_yielder = input_yielder
      @queue = Queue.new
    end

    def run
      @session_yielder.call do |session|
        @input_yielder.call do |input|
          session.request(:nvim_ui_attach, *@dimensions, {})

          Thread.new do
            session.run do |message|
              @queue << Proc.new do
                Event.received(message, @handlers)
              end
            end
          end

          Thread.new do
            loop do
              key = input.getc
              @queue << Proc.new { session.notify(:nvim_input, key) }
            end
          end

          loop { @queue.pop.call }
        end
      end
    rescue IOError => e
      warn "Got #{e}, exiting."
    end
  end
end
