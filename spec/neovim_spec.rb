require "spec_helper"

RSpec.describe Neovim do
  describe ".ui" do
    it "creates an event loop that receives ui events" do
      event = nil

      ui = Neovim.ui do |ui|
        ui.input = STDIN
        ui.dimensions = [10, 10]
        ui.child_args = ["nvim", "--embed"]

        ui.on(:redraw) do |redraw_event|
          event = redraw_event
          throw(:done)
        end
      end

      catch(:done) do
        ui.run
      end

      expect(event.method_name).to eq("redraw")
      expect(event.arguments).to respond_to(:to_ary)
    end
  end
end
