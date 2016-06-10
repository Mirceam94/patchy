require "gosu"

module Patchy
  class Renderer < Gosu::Window
    def initialize(input_q, output_q)
      super(485, 485, {
        :update_interval => 33.3333333 # 30 fps
      })

      @caption = "Patchy Renderer"
      @input_q = input_q
      @output_q = output_q
      @matrix_state = []
      @dirty = true

      # Initialize display state (0bRGB)
      16.times do
        @matrix_state.push(Array.new(16, 0b000))
      end
    end

    def update
      return if @input_q.empty?
      packet = @input_q.pop

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
      @dirty = true
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

      @dirty = false
    end

    ###
    # Prevents the screen from being constantly redrawn. Ship our dirty flag to
    # Gosu
    #
    # @return {Boolean} needs_redraw
    ###
    def needs_redraw?
      @dirty
    end

    ###
    # Called when a key is pressed, enables the corresponding flag in the first
    # input port.
    #
    # @param {Key} id
    ###
    def button_down(id)
      if id == Gosu::KbW
        @output_q.button_down(:w)
      elsif id == Gosu::KbS
        @output_q.button_down(:s)
      elsif id == Gosu::KbEscape
        @output_q.button_down(:esc)
      end
    end

    ###
    # Called when a key is pressed, disables the corresponding flag in the first
    # input port.
    #
    # @param {Key} id
    ###
    def button_up(id)
      if id == Gosu::KbW
        @output_q.button_up(:w)
      elsif id == Gosu::KbS
        @output_q.button_up(:s)
      elsif id == Gosu::KbEscape
        @output_q.button_up(:esc)
      end
    end
  end
end
