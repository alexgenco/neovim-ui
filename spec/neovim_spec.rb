require "spec_helper"
require "timeout"

RSpec.describe Neovim do
  around do |spec|
    Timeout.timeout(1) { spec.run }
  end

  specify ".ui" do
    rd, wr = IO.pipe

    ui = Neovim.ui do |ui|
      ui.input = rd
      ui.dimensions = [10, 10]
      ui.child_args = ["nvim", "--embed"]

      ui.on(:redraw) do |event|
        Fiber.yield(:redraw, event)
      end

      ui.on(:input) do |key|
        Fiber.yield(:input, key)
      end
    end

    fiber = Fiber.new { ui.run }

    type, event = fiber.resume
    expect(type).to eq(:redraw)
    expect(event.method_name).to eq("redraw")
    expect(event.arguments).to respond_to(:to_ary)

    wr.print("i")

    loop do
      type, key = fiber.resume

      if type == :input
        expect(key).to eq("i")
        break
      end
    end
  end
end
