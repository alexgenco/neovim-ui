require "neovim/ui"
require "logger"

$logger = Logger.new("/tmp/nvim-ui.log")

Neovim.ui do |ui|
  ui.dimensions = [10, 10]
  ui.child_args = ["nvim", "--embed"]

  ui.on(:*) do |message|
    $logger.debug("Got #{message.method_name}: #{message.arguments}")
  end

  ui.on(:redraw) do |message|
    $logger.debug("Got redraw: #{message.arguments}")
  end

  ui.on(:input) do |key|
    $logger.debug("Got input: #{key.inspect}")
  end
end.run
