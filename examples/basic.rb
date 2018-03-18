require "neovim/ui"
require "logger"

$logger = Logger.new("/tmp/nvim-ui.log")

Neovim.ui do |ui|
  ui.dimensions = [10, 10]

  ui.backend do |backend|
    backend.attach_child(["nvim", "-u", "NONE", "--embed"])
  end

  ui.frontend do |frontend|
    frontend.attach(STDIN)
  end

  ui.on(:redraw) do |message|
    $logger.debug("Got redraw: #{message.arguments}")
  end

  ui.on(:input) do |key|
    $logger.debug("Got input: #{key.inspect}")
  end
end.run
