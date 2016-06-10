module Patchy
  class CPUMessenger < Queue

    def button_up(id)
      push({
        :cmd => :btn_up,
        :id => id
      })
    end

    def button_down(id)
      push({
        :cmd => :btn_down,
        :id => id
      })
    end

  end
end
