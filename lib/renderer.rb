require "gosu"

module Patchy
  class Renderer < Gosu::Window
    def initialize(messenger)
      super 485, 485

      @caption = "Patchy Renderer"
      @messenger = messenger
      @matrix_state = []

      # Initialize display state (0bRGB)
      16.times do
        @matrix_state.push(Array.new(16, 0b000))
      end
    end

    def update
      return if @messenger.empty?
      packet = @messenger.pop

      case packet[:cmd]
      when :close then close
      when :spx then set_px(packet[:x], packet[:y], packet[:col])
      end
    end

    ###
    # Set a pixel color by x,y pair
    #
    # @param [Number] x 0 - 15
    # @param [Number] y 0 - 15
    # @param [Number] col 0bRGB
    ###
    def set_px(x, y, col)
      @matrix_state[x][y] = col
    end

    def draw
      @matrix_state.each_with_index do |col, x|
        col.each_with_index do |val, y|
          r = (val & 0b100) > 0 ? 255 : 0
          g = (val & 0b010) > 0 ? 255 : 0
          b = (val & 0b001) > 0 ? 255 : 0

          # Disabled LEDs are still visible in real life, so show them as gray
          if r == g && g == b && b == 0 then
            r = g = b = 50
          end

          color = Gosu::Color.new(255, r, g, b)

          Gosu.draw_rect(5 + (x * 30), 5 + (y * 30), 25, 25, color)
        end
      end
    end
  end
end
