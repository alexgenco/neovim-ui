require "neovim"
require "neovim/event_loop"
require "neovim/executable"
require "neovim/session"

module Neovim
  class UI
    def initialize(dimensions, child_args, handlers)
      @dimensions = dimensions
      @child_args = child_args
      @handlers = handlers
    end

    def run
      event_loop = EventLoop.child(@child_args)
      session = Session.new(event_loop)

      session.request(:nvim_ui_attach, *@dimensions, {})

      session.run do |message|
        @handlers[message.method_name.to_sym].each do |handler|
          handler.call(message, session)
        end
      end
    end
  end
end
