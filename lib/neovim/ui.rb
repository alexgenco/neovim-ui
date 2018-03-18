require "neovim"
require "neovim/event_loop"
require "neovim/executable"
require "neovim/session"
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
      @input.raw do
        event_loop = EventLoop.child(@child_args)
        session = Session.new(event_loop)

        session.request(:nvim_ui_attach, *@dimensions, {})

        neovim_event_thread = Thread.new { neovim_event_loop(session) }
        user_input_thread = Thread.new { user_input_loop }

        handle_events(session)
      end
    end

    private

    def neovim_event_loop(session)
      session.run do |message|
        @event_queue.enq(message)
      end
    end

    def user_input_loop
      loop do
        @event_queue.enq(@input.getc)
      end
    end

    def handle_events(session)
      loop do
        @event_queue.deq.tap do |message|
          if message.respond_to?(:method_name)
            (@handlers[message.method_name.to_sym] + @handlers[:*]).each do |handler|
              handler.call(message)
            end
          else
            @handlers[:input].each { |handler| handler.call(message) }
            session.notify(:nvim_input, message)
          end
        end
      end
    end
  end
end
