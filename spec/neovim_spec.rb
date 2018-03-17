require "spec_helper"

RSpec.describe Neovim do
  describe ".ui" do
    it "creates an event loop that receives ui events" do
      event = nil

      ui = Neovim.ui do |ui|
        ui.dimensions = [10, 10]
        ui.child_args = ["nvim", "--embed"]

        ui.on(:redraw) do |redraw_event, session|
          event = redraw_event
          session.shutdown
        end
      end

      ui.run

      expect(event.method_name).to eq("redraw")
      expect(event.arguments).to respond_to(:to_ary)
    end
  end
end
