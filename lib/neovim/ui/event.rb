module Neovim
  class UI
    class Event < Struct.new(:name, :arguments)
      def self.redraw_batch(message, handlers)
        Proc.new do
          message.arguments.each do |(name, arguments)|
            event = Event.new(name.to_sym, arguments)

            handlers[:redraw][:__all__].each do |handler|
              handler.call(event)
            end

            handlers[:redraw][name.to_sym].each do |handler|
              handler.call(event)
            end
          end
        end
      end

      def self.input(keyseq, handlers)
        Proc.new do |session|
          event = Event.new(:input, [keyseq])

          handlers[:input][:__all__].each { |handler| handler.call(event) }
          handlers[:input][keyseq.to_sym].each { |handler| handler.call(event) }

          event.arguments.each do |key|
            session.notify(:nvim_input, key)
          end
        end
      end
    end
  end
end
