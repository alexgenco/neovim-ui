# Print all redraw and input events to stdout.
#
# You can exit the example by hitting `<esc>:qa!<enter><enter>`
# (as if you were exiting vim, plus an additional `<enter>`)
#
require "neovim/ui"
require "logger"

Neovim.ui do |ui|
  ui.dimensions = [10, 10]

  ui.backend do |backend|
    backend.attach_child(["nvim", "-u", "NONE"])
  end

  ui.frontend do |frontend|
    frontend.attach(STDIN)
  end

  ui.on(:redraw) do |message|
    puts "REDRAW: #{message.arguments.inspect}\r"
  end

  ui.on(:input) do |key|
    puts "INPUT: #{key.inspect}\r"
  end
end.run
