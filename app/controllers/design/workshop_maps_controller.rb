module Design
  class WorkshopMapsController < ApplicationController
    def show
      @stations = [
        { key: :foundations, state: :completed },
        { key: :internet, state: :completed },
        { key: :data, state: :current },
        { key: :rails, state: :locked },
        { key: :browser, state: :locked },
        { key: :production, state: :locked }
      ]
      @teams = %i[copper teal]
    end
  end
end
