module Neovim
  class UI
    class Event < Struct.new(:name, :arguments)
      def self.received(message, handlers)
        message.arguments.each do |(name, arguments)|
          event = Event.new(name.to_sym, arguments)

          handlers[:__all__].each do |handler|
            handler.call(event)
          end

          handlers[name.to_sym].each do |handler|
            handler.call(event)
          end
        end
      end
    end
  end
end
