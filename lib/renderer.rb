require "gosu"

module Patchy
  class Renderer < Gosu::Window
    def initialize(messenger)
      super 640, 480

      @caption = "Patchy Renderer"
      @messenger = messenger
    end

    def update
      return if @messenger.empty?
      packet = @messenger.pop

      case packet[:cmd]
      when :close then close
      end
    end

    def draw
      Gosu.draw_rect(0, 0, 50, 50, Gosu::Color::RED)
    end
  end
end
