module Neovim
  class UI
    class Event < Struct.new(:name, :arguments)
      def self.redraw_batch(message, handlers)
        Proc.new do
          message.arguments.each do |(name, arguments)|
            handlers[:redraw].each do |handler|
              handler.call Event.new(name.to_sym, arguments)
            end
          end
        end
      end

      def self.input(keyseq, handlers)
        Proc.new do |session|
          event = Event.new(:input, [keyseq])

          handlers[:redraw].each { |handler| handler.call(event) }

          event.arguments.each do |key|
            session.notify(:nvim_input, key)
          end
        end
      end
    end
  end
end
