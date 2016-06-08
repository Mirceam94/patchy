module Patchy
  class RendererMessenger < Queue

    def close
      push({
        :cmd => :close
      })
    end

  end
end
