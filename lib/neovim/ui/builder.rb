require "neovim/ui"
require "neovim/executable"
require "io/console"

module Neovim
  class UI
    class Builder < BasicObject
      attr_writer :dimensions

      def initialize(&block)
        @dimensions = ::IO.console.winsize
        @session_yielder = ->() { raise("Must configure a backend") }
        @input_yielder = ->() { raise("Must configure a frontend") }

        @handlers = ::Hash.new do |hash, key|
          hash[key] = ::Hash.new { |h, k| h[k] = [] }
        end

        yield self
      end

      def on(event, name=:__all__, &block)
        @handlers[event.to_sym][name.to_sym] << block
      end

      def backend(&block)
        @session_yielder = Backend.new(&block).__send__(:session_yielder)
      end

      def frontend(&block)
        @input_yielder = Frontend.new(&block).__send__(:input_yielder)
      end

      private

      def build
        UI.new(@dimensions, @handlers, @session_yielder, @input_yielder)
      end

      class Backend
        def initialize
          yield self
        end

        def attach_child(argv=[Neovim::Executable.from_env.path])
          @session_yielder = lambda do |&block|
            event_loop = EventLoop.child(Array(argv))
            session = Session.new(event_loop)

            block.call(session)
          end
        end

        def attach_unix(socket_path)
          @session_yielder = lambda do |&block|
            event_loop = EventLoop.unix(socket_path)
            session = Session.new(event_loop)

            block.call(session)
          end
        end

        def attach_tcp(host, port)
          @session_yielder = lambda do |&block|
            event_loop = EventLoop.tcp(host, port)
            session = Session.new(event_loop)

            block.call(session)
          end
        end

        private

        attr_reader :session_yielder
      end

      class Frontend
        def initialize
          yield self
        end

        def attach(input)
          @input_yielder = lambda do |&block|
            if input.tty? && input.respond_to?(:raw)
              input.raw(&block)
            else
              block.call(input)
            end
          end
        end

        private

        attr_reader :input_yielder
      end
    end
  end
end
