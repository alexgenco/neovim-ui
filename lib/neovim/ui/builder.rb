require "neovim/ui"
require "neovim/executable"
require "io/console"

module Neovim
  class UI
    class Builder < BasicObject
      attr_writer :dimensions, :child_args

      def initialize(&block)
        @dimensions = ::IO.console.winsize
        @child_args = [::Neovim::Executable.from_env.path]
        @handlers = ::Hash.new { |hash, key| hash[key] = [] }

        yield self
      end

      def on(event, &block)
        @handlers[event.to_sym] << block
      end

      private

      def build
        UI.new(@dimensions, @child_args, @handlers)
      end
    end
  end
end
