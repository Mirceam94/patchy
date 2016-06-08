module Patchy
  class RendererMessenger < Queue

    def close
      push({
        :cmd => :close
      })
    end

    def set_px(x, y, col)
      push({
        :cmd => :spx,
        :x => x,
        :y => y,
        :col => col
      })
    end

  end
end
