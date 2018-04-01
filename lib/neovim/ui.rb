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
    def initialize(
      dimensions,
      redraw_handlers,
      session_yielder,
      input_yielder,
      key_yielder
    )
      @dimensions = dimensions
      @redraw_handlers = redraw_handlers
      @session_yielder = session_yielder
      @input_yielder = input_yielder
      @key_yielder = key_yielder
      @queue = Queue.new
    end

    def run
      @session_yielder.call do |session|
        @input_yielder.call do |input|
          session.request(:nvim_ui_attach, *@dimensions, {})

          Thread.new do
            session.run do |message|
              @queue << lambda do
                Event.received(message, @redraw_handlers)
              end
            end
          end

          Thread.new do
            loop do
              @key_yielder.call(input) do |key|
                @queue << lambda do
                  session.notify(:nvim_input, key)
                end
              end
            end
          end

          loop { @queue.pop.call }
        end
      end
    end
  end
end
