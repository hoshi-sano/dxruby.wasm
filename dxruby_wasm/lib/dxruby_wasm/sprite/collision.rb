# frozen_string_literal: true

module DXRubyWasm
  class Sprite
    module Collision
      module HitBox
        class Base
          # SAT-based collision detection: polygon vs polygon
          def polygons_collide?(poly1, poly2)
            [poly1, poly2].each do |polygon|
              polygon.each_with_index do |current_p, idx|
                next_p = polygon[(idx + 1) % polygon.size]

                edge = vector_subtract(next_p, current_p)
                axis = normalize(-edge[1], edge[0])

                proj1 = project_polygon(poly1, axis)
                proj2 = project_polygon(poly2, axis)

                return false unless overlap?(proj1, proj2)
              end
            end
            true
          end

          # Projects a polygon onto an axis and
          # returns the min and max scalar values
          def project_polygon(polygon, axis)
            min = max = vector_dot_product(polygon[0], axis)
            polygon.each do |point|
              projection = vector_dot_product(point, axis)
              min = [min, projection].min
              max = [max, projection].max
            end
            [min, max]
          end

          def vector_dot_product(a, b)
            a[0] * b[0] + a[1] * b[1]
          end

          def vector_subtract(a, b)
            [a[0] - b[0], a[1] - b[1]]
          end

          def normalize(a, b)
            len = Math.sqrt(a**2 + b**2)
            return [0, 0] if len == 0
            [a / len, b / len]
          end

          # Returns true if two projection intervals overlap
          def overlap?(proj1, proj2)
            !(proj1[1] < proj2[0] || proj2[1] < proj1[0])
          end

          def distance_squared(a, b)
            dx, dy = vector_subtract(a, b)
            dx * dx + dy * dy
          end
        end

        class Point < Base
          def initialize(sprite, x, y)
            @sprite, @x, @y = sprite, x, y
            super()
          end

          def collide?(other)
            case other
            when Point
              absolute_pos == other.absolute_pos
            when Circle
              in_circle?(other.absolute_pos, other.r)
            when Rect, Triangle
              in_polygon?(other.absolute_poss)
            end
          end

          def absolute_pos
            [@sprite.absolute_x + @x, @sprite.absolute_y + @y]
          end

          # Point-in-polygon collision detection using the Ray Casting
          def in_polygon?(polygon_poss)
            px, py = absolute_pos
            inside = false

            prev_index = polygon_poss.length - 1
            polygon_poss.each_with_index do |current_pos, current_index|
              # Consider the edge (line segment) formed by
              # `(current_x, current_y)` and `(prev_x, prev_y)`
              current_x, current_y = current_pos
              prev_x, prev_y = polygon_poss[prev_index]

              # Check if the edge crosses the `py`
              if (current_y > py) != (prev_y > py)
                intersect_x = current_x +
                              (prev_x - current_x) *
                              (py - current_y) / (prev_y - current_y + 1e-10)
                if px < intersect_x
                  # If the point crosses an odd number of edges, it's inside the polygon
                  inside = !inside
                end
              end

              prev_index = current_index
            end

            inside
          end

          def in_circle?(circle_center, radius)
            distance_squared(absolute_pos, circle_center) <= radius * radius
          end
        end

        class Circle < Base
          attr_reader :r

          def initialize(sprite, x, y, r)
            @sprite, @x, @y, @r = sprite, x, y, r
            super()
          end

          def absolute_pos
            [@sprite.absolute_x + @x, @sprite.absolute_y + @y]
          end

          def collide?(other)
            case other
            when Point
              other.collides?(self)
            when Circle
              circles_collide?(absolute_pos, @r, other.absolute_pos, other.r)
            when Rect, Triangle
              polygon_circle_collide?(other.absolute_poss, absolute_pos, @r)
            end
          end

          def project_circle(center, radius, axis)
            center_proj = vector_dot_product(center, axis)
            [center_proj - radius, center_proj + radius]
          end

          # SAT-based collision detection: polygon vs circle
          #
          # Detects collision if projections overlap on all axes:
          # 1: Polygon edge normals
          # 2: Axis from circle center to nearest polygon vertex
          def polygon_circle_collide?(polygon, circle_center, radius)
            # 1:
            polygon.each_with_index do |current_p, idx|
              next_p = polygon[(idx + 1) % polygon.size]

              edge = vector_subtract(next_p, current_p)
              axis = normalize(-edge[1], edge[0])

              proj_poly = project_polygon(polygon, axis)
              proj_circle = project_circle(circle_center, radius, axis)

              return false unless overlap?(proj_poly, proj_circle)
            end

            # 2:
            nearest_point = polygon.min_by do |point|
              dx = point[0] - circle_center[0]
              dy = point[1] - circle_center[1]
              dx * dx + dy * dy
            end
            axis = normalize(*vector_subtract(nearest_point, circle_center))
            proj_poly = project_polygon(polygon, axis)
            proj_circle = project_circle(circle_center, radius, axis)
            return false unless overlap?(proj_poly, proj_circle)

            true # projections overlap on all axes
          end

          def circles_collide?(center1, radius1, center2, radius2)
            dist_sq = distance_squared(center1, center2)
            radius_sum = radius1 + radius2
            dist_sq <= radius_sum * radius_sum
          end
        end

        class Rect < Base
          def initialize(sprite, x1, y1, x2, y2)
            @sprite, @x1, @y1, @x2, @y2 = sprite, x1, y1, x2, y2
            super()
          end

          def collide?(other)
            case other
            when Point, Circle
              other.collide?(self)
            when Rect, Triangle
              polygons_collide?(absolute_poss, other.absolute_poss)
            end
          end

          def absolute_poss
            # TODO: Consider angle, scale, ... and so on
            [[@x1 + @sprite.x, @y1 + @sprite.y],
             [@x2 + @sprite.x, @y1 + @sprite.y],
             [@x2 + @sprite.x, @y2 + @sprite.y],
             [@x1 + @sprite.x, @y2 + @sprite.y]]
          end
        end

        class Triangle < Base
          def initialize(sprite, x1, y1, x2, y2, x3, y3)
            @sprite = sprite
            @poss = [[x1, y1], [x2, y2], [x3, y3]]
            super()
          end

          def collide?(other)
            case other
            when Point, Circle
              other.collide?(self)
            when Rect, Triangle
              polygons_collide?(absolute_poss, other.absolute_poss)
            end
          end

          def absolute_poss
            # TODO: Consider angle, scale, ... and so on
            [[@poss[0][0] + @sprite.x, @poss[0][1] + @sprite.y],
             [@poss[1][0] + @sprite.x, @poss[1][1] + @sprite.y],
             [@poss[2][0] + @sprite.x, @poss[2][1] + @sprite.y]]
          end
        end
      end

      module ClassMethods
        def check(o_sprites, d_sprites, shot = :shot, hit = :hit)
          res = false
          o_sprites = Array(o_sprites).select { |s| s.is_a?(Sprite) }
          d_sprites = Array(d_sprites).select { |s| s.is_a?(Sprite) }
          discards = []
          o_sprites.each do |o_sprite|
            next if discards.include?(o_sprite)

            d_sprites.each do |d_sprite|
              break if discards.include?(o_sprite)
              next if discards.include?(d_sprite)
              next if o_sprite.object_id == d_sprite.object_id

              if o_sprite === d_sprite
                res = true
                discard = false
                if o_sprite.respond_to?(shot) && shot
                  discard = (o_sprite.send(shot, d_sprite) == :discard)
                end
                if d_sprite.respond_to?(hit) && hit
                  discard = (d_sprite.send(hit, o_sprite) == :discard)
                end
                if discard
                  discards << o_sprite
                  discards << d_sprite
                end
              end
            end
          end
          res
        end
      end

      attr_reader :collision
      attr_accessor :collision_enable
      attr_accessor :collision_sync
      attr_reader :hitbox

      def shot(other)
      end

      def hit(other)
      end

      def collision=(hitbox)
        @hitbox =
          case hitbox.length
          when 2 then HitBox::Point.new(self, *hitbox)
          when 3 then HitBox::Circle.new(self, *hitbox)
          when 4 then HitBox::Rect.new(self, *hitbox)
          when 6 then HitBox::Triangle.new(self, *hitbox)
          else
            raise "Inlivad argument for 'collision=': #{hitbox}"
          end
        @collision = hitbox
      end

      def ===(sprite)
        check(sprite).any?
      end

      def check(sprite)
        Array(sprite).select { |s| collide?(sprite) }
      end

      def collidable?
        !@vanished && @collision_enable
      end

      private

      def collide?(sprite)
        return false if !collidable? || !sprite.collidable?
        @hitbox.collide?(sprite.hitbox)
      end
    end
  end
end
