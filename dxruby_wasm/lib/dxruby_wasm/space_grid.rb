# frozen_string_literal: true

require 'set'

module DXRubyWasm
  # A spatial partitioning grid to optimize collision detection
  class SpaceGrid
    def initialize(cell_width, cell_height)
      @cell_width = cell_width
      @cell_height = cell_height
      @grid = Hash.new { |h, k| h[k] = Set.new }
    end

    # Adds a sprite to the grid
    def add(sprite)
      return unless sprite.collidable?

      min_x, min_y, max_x, max_y = sprite.hitbox.aabb

      start_x = (min_x / @cell_width).to_i
      start_y = (min_y / @cell_height).to_i
      end_x = (max_x / @cell_width).to_i
      end_y = (max_y / @cell_height).to_i

      (start_y..end_y).each do |y|
        (start_x..end_x).each do |x|
          @grid[[x, y]].add(sprite)
        end
      end
    end

    # Returns a set of sprites that could potentially collide with the given sprite
    def get_candidates(sprite)
      return Set.new unless sprite.collidable?

      min_x, min_y, max_x, max_y = sprite.hitbox.aabb

      start_x = (min_x / @cell_width).to_i
      start_y = (min_y / @cell_height).to_i
      end_x = (max_x / @cell_width).to_i
      end_y = (max_y / @cell_height).to_i

      candidates = Set.new
      (start_y..end_y).each do |y|
        (start_x..end_x).each do |x|
          candidates.merge(@grid[[x, y]])
        end
      end
      candidates.delete(sprite)
      candidates
    end
  end
end
