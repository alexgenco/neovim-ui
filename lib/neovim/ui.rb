require "neovim"
require "neovim/event_loop"
require "neovim/executable"
require "neovim/session"
require "neovim/ui/event"
require "io/console"
require "thread"

module Neovim
  class UI
    def initialize(input, dimensions, child_args, handlers)
      @input = input
      @dimensions = dimensions
      @child_args = child_args
      @handlers = handlers
      @event_queue = Queue.new
    end

    def run
      raw_tty do
        event_loop = EventLoop.child(@child_args)
        session = Session.new(event_loop)

        session.request(:nvim_ui_attach, *@dimensions, {})

        Thread.new do
          session.run do |message|
            event = Event.redraw(message)
            @event_queue.enq(event)
          end
        end

        Thread.new do
          loop do
            event = Event.input(@input.getc)
            @event_queue.enq(event)
          end
        end

        loop do
          event = @event_queue.deq
          event.received(@handlers, session)
        end
      end
    end

    private

    def raw_tty(&block)
      if @input.tty? && @input.respond_to?(:raw)
        @input.raw(&block)
      else
        block.call
      end
    end
  end
end
