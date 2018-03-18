require "neovim/ui"
require "neovim/executable"
require "io/console"

module Neovim
  class UI
    class Builder < BasicObject
      attr_writer :dimensions

      def initialize(&block)
        @dimensions = ::IO.console.winsize
        @handlers = ::Hash.new { |hash, key| hash[key] = [] }
        @session_builder = ->() { raise("Must configure a backend") }
        @input_builder = ->() { raise("Must configure a frontend") }

        yield self
      end

      def on(event, &block)
        @handlers[event.to_sym] << block
      end

      def backend(&block)
        @session_builder = Backend.new(&block).__send__(:session_builder)
      end

      def frontend(&block)
        @input_builder = Frontend.new(&block).__send__(:input_builder)
      end

      private

      def build
        UI.new(@dimensions, @handlers, @session_builder, @input_builder)
      end

      class Backend
        def initialize
          yield self
        end

        def attach_child(argv=[Neovim::Executable.from_env.path])
          @session_builder = lambda do |&block|
            event_loop = EventLoop.child(Array(argv))
            session = Session.new(event_loop)

            block.call(session)
          end
        end

        private

        attr_reader :session_builder
      end

      class Frontend
        def initialize
          yield self
        end

        def attach(input)
          @input_builder = lambda do |&block|
            if input.tty? && input.respond_to?(:raw)
              input.raw(&block)
            else
              block.call(input)
            end
          end
        end

        private

        attr_reader :input_builder
      end
    end
  end
end
