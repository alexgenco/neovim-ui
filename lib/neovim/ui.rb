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
      @queue = Queue.new
    end

    def run
      @session_builder.call do |session|
        @input_builder.call do |input|
          session.request(:nvim_ui_attach, *@dimensions, {})

          Thread.new do
            session.run do |message|
              event = Event.redraw_batch(message, @handlers)
              @queue.enq(event)
            end
          end

          Thread.new do
            loop do
              event = Event.input(input.getc, @handlers)
              @queue.enq(event)
            end
          end

          loop do
            @queue.deq.call(session)
          end
        end
      end
    rescue IOError => e
      warn "Got #{e}, exiting."
    end
  end
end
