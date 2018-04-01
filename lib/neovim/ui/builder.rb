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
        @key_yielder = ->() { raise("Must configure a frontend") }
        @redraw_handlers = ::Hash.new { |hash, key| hash[key] = [] }

        yield self
      end

      def redraw(name=:__all__, &block)
        @redraw_handlers[name.to_sym] << block
      end

      def backend(&block)
        @session_yielder = Backend.new(&block).__send__(:session_yielder)
      end

      def frontend(&block)
        Frontend.new(&block).tap do |frontend|
          @input_yielder = frontend.__send__(:input_yielder)
          @key_yielder = frontend.__send__(:key_yielder)
        end
      end

      private

      def build
        UI.new(
          @dimensions,
          @redraw_handlers,
          @session_yielder,
          @input_yielder,
          @key_yielder
        )
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
          input = input.to_io

          @input_yielder = lambda do |&block|
            if input.tty? && input.respond_to?(:raw)
              input.raw { |raw_input| block.call(raw_input) }
            else
              block.call(input)
            end
          end

          @key_yielder ||= lambda do |input_stream, &block|
            block.call(input_stream.getc)
          end
        end

        def read_key(&reader)
          @input_yielder ||= lambda do |&block|
            block.call(nil)
          end

          @key_yielder = lambda do |input_stream, &block|
            block.call(reader.call(input_stream))
          end
        end

        private

        attr_reader :input_yielder, :key_yielder
      end
    end
  end
end
