module Neovim
  class UI
    module Handler
      def self.redraw_batch(message, handlers)
        Proc.new do
          message.arguments.each do |(event_name, arguments)|
            handlers[:redraw].each do |handler|
              handler.call(message)
            end
          end
        end
      end
    end
  end
end
