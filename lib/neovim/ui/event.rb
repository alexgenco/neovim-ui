module Neovim
  class UI
    module Event
      def self.redraw(message)
        Redraw.new(message)
      end

      def self.input(key)
        Input.new(key)
      end

      Redraw = Struct.new(:message) do
        def received(handlers, _)
          handlers[message.method_name.to_sym].each do |handler|
            handler.call(message)
          end
        end
      end

      Input = Struct.new(:key) do
        def received(handlers, session)
          handlers[:input].each { |handler| handler.call(key) }
          session.notify(:nvim_input, key)
        end
      end
    end
  end
end
