require "neovim"
require "neovim/ui/builder"

module Neovim
  def self.ui(&block)
    UI::Builder.new(&block).__send__(:build)
  end
end
