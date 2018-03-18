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

    def initialize(dimensions, handlers, session_builder, input_builder)
      @dimensions = dimensions
      @handlers = handlers
      @session_builder = session_builder
      @input_builder = input_builder
      @event_queue = Queue.new
    end

    def run
      @session_builder.call do |session|
        @input_builder.call do |input|
          session.request(:nvim_ui_attach, *@dimensions, {})

          Thread.new do
            session.run do |message|
              event = Event.redraw(message)
              @event_queue.enq(event)
            end
          end

          Thread.new do
            loop do
              event = Event.input(input.getc)
              @event_queue.enq(event)
            end
          end

          loop do
            event = @event_queue.deq
            event.received(@handlers, session)
          end
        end
      end
    rescue IOError => e
      warn "Got #{e}, exiting."
    end
  end
end
