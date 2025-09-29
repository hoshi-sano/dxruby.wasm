# frozen_string_literal: true

module DXRubyWasm
  class Sprite
    module Collision
      CHECK_FUNCTIONS_JS = <<~JS
        window.DXRubyWasmCollision ||= {};
        Object.assign(window.DXRubyWasmCollision, {
          aabb_collide: (box1, box2) => {
            // box = [min_x, min_y, max_x, max_y]
            return !(box1[2] < box2[0] ||
                     box1[0] > box2[2] ||
                     box1[3] < box2[1] ||
                     box1[1] > box2[3]);
          },

          vector_subtract: (a, b) => {
            return [a[0] - b[0], a[1] - b[1]];
          },

          vector_dot_product: (a, b) => {
            return a[0] * b[0] + a[1] * b[1];
          },

          normalize: (a, b) => {
            const len = Math.sqrt(a*a + b*b);
            if (len === 0) return [0, 0];
            return [a / len, b / len];
          },

          project_polygon: (polygon, axis) => {
            let min = window.DXRubyWasmCollision.vector_dot_product(polygon[0], axis);
            let max = min;
            for (let i = 1; i < polygon.length; i++) {
              const projection = window.DXRubyWasmCollision.vector_dot_product(polygon[i], axis);
              if (projection < min) {
                min = projection;
              }
              if (projection > max) {
                max = projection;
              }
            }
            return [min, max];
          },

          overlap: (proj1, proj2) => {
            return !(proj1[1] < proj2[0] || proj2[1] < proj1[0]);
          },

          polygons_collide: (poly1, poly2) => {
            const polygons = [poly1, poly2];
            for (let i = 0; i < polygons.length; i++) {
              const polygon = polygons[i];
              for (let j = 0; j < polygon.length; j++) {
                const current_p = polygon[j];
                const next_p = polygon[(j + 1) % polygon.length];

                const edge = window.DXRubyWasmCollision.vector_subtract(next_p, current_p);
                const axis = window.DXRubyWasmCollision.normalize(-edge[1], edge[0]);

                const proj1 = window.DXRubyWasmCollision.project_polygon(poly1, axis);
                const proj2 = window.DXRubyWasmCollision.project_polygon(poly2, axis);

                if (!window.DXRubyWasmCollision.overlap(proj1, proj2)) {
                  return false;
                }
              }
            }
            return true;
          },

          project_circle: (center, radius, axis) => {
            const center_proj = window.DXRubyWasmCollision.vector_dot_product(center, axis);
            return [center_proj - radius, center_proj + radius];
          },

          polygon_circle_collide: (polygon, circle_center, radius) => {
            // 1: Polygon edge normals
            for (let i = 0; i < polygon.length; i++) {
              const current_p = polygon[i];
              const next_p = polygon[(i + 1) % polygon.length];

              const edge = window.DXRubyWasmCollision.vector_subtract(next_p, current_p);
              const axis = window.DXRubyWasmCollision.normalize(-edge[1], edge[0]);

              const proj_poly = window.DXRubyWasmCollision.project_polygon(polygon, axis);
              const proj_circle = window.DXRubyWasmCollision.project_circle(circle_center, radius, axis);

              if (!window.DXRubyWasmCollision.overlap(proj_poly, proj_circle)) {
                return false;
              }
            }

            // 2: Axis from circle center to nearest polygon vertex
            let nearest_dist_sq = Infinity;
            let nearest_point = null;
            for (let i = 0; i < polygon.length; i++) {
              const point = polygon[i];
              const dx = point[0] - circle_center[0];
              const dy = point[1] - circle_center[1];
              const dist_sq = dx * dx + dy * dy;
              if (dist_sq < nearest_dist_sq) {
                nearest_dist_sq = dist_sq;
                nearest_point = point;
              }
            }

            const axis = window.DXRubyWasmCollision.normalize(
              nearest_point[0] - circle_center[0],
              nearest_point[1] - circle_center[1]
            );
            const proj_poly = window.DXRubyWasmCollision.project_polygon(polygon, axis);
            const proj_circle = window.DXRubyWasmCollision.project_circle(circle_center, radius, axis);
            if (!window.DXRubyWasmCollision.overlap(proj_poly, proj_circle)) {
              return false;
            }

            return true;
          },

          calculate_aabb: (poss) => {
            let min_x = poss[0][0];
            let min_y = poss[0][1];
            let max_x = poss[0][0];
            let max_y = poss[0][1];
            for (const [x, y] of poss) {
              if (x < min_x) min_x = x;
              if (y < min_y) min_y = y;
              if (x > max_x) max_x = x;
              if (y > max_y) max_y = y;
            }
            return [min_x, min_y, max_x, max_y];
          },

          transformed: (poss, origin_x, origin_y, collision_sync, cx, cy, sx, sy, angle) => {
            if (!collision_sync) {
              return poss.map(([x, y]) => [origin_x + x, origin_y + y]);
            }

            const rad = angle * Math.PI / 180;
            const cos = Math.cos(rad);
            const sin = Math.sin(rad);

            return poss.map(([x, y]) => {
              return [
                (x - cx) * sx * cos - (y - cy) * sy * sin + cx + origin_x,
                (x - cx) * sx * sin + (y - cy) * sy * cos + cy + origin_y,
              ];
            });
          },

          in_polygon: (point, polygon_poss) => {
            const [px, py] = point;
            let inside = false;

            for (let i = 0, j = polygon_poss.length - 1; i < polygon_poss.length; j = i++) {
              const [xi, yi] = polygon_poss[i];
              const [xj, yj] = polygon_poss[j];

              const intersect = ((yi > py) !== (yj > py)) &&
                (px < (xj - xi) * (py - yi) / (yj - yi) + xi);
              if (intersect) inside = !inside;
            }

            return inside;
          },

          transformed_circle: (x, y, r, segments, origin_x, origin_y, collision_sync, cx, cy, sx, sy, angle) => {
            const angle_step = 2 * Math.PI / segments;
            const circle_poss = [];
            for (let i = 0; i < segments; i++) {
              const current_rad = i * angle_step;
              circle_poss.push([x + Math.cos(current_rad) * r, y + Math.sin(current_rad) * r]);
            }
            return window.DXRubyWasmCollision.transformed(circle_poss, origin_x, origin_y, collision_sync, cx, cy, sx, sy, angle);
          },
        });
      JS
      JS.eval(CHECK_FUNCTIONS_JS)
      private_constant :CHECK_FUNCTIONS_JS

      module HitBox
        class Base
          def _js_runner
            Sprite._js_runner
          end

          # SAT-based collision detection: polygon vs polygon
          def polygons_collide?(poly1, poly2)
            _js_runner.polygons_collide?(poly1, poly2)
          end

          def distance_squared(a, b)
            dx, dy = _js_runner.vector_subtract(a, b).to_a.map(&:to_i)
            dx * dx + dy * dy
          end

          def calculate_aabb(poss)
            return [0, 0, 0, 0] if poss.empty?
            _js_runner.calculate_aabb(poss).to_a.map(&:to_i)
          end

          def transformed(poss)
            _js_runner.transformed(poss, @sprite.absolute_x, @sprite.absolute_y,
                                   @sprite.collision_sync, @sprite.center_x, @sprite.center_y,
                                   @sprite.scale_x, @sprite.scale_y, @sprite.angle).to_a.map { |p| p.to_a.map(&:to_i) }
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
              if other.ellipse?
                in_polygon?(other.transformed_circle)
              else
                in_circle?(other.absolute_pos, other.r)
              end
            when Rect, Triangle
              in_polygon?(other.absolute_poss)
            end
          end

          def absolute_pos
            transformed([[@x, @y]]).first
          end

          def aabb
            x, y = absolute_pos
            [x, y, x, y]
          end

          # Point-in-polygon collision detection using the Ray Casting
          def in_polygon?(polygon_poss)
            px, py = absolute_pos
            _js_runner.in_polygon?([px, py], polygon_poss)
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

          def ellipse?
            @sprite.scale_x != @sprite.scale_y
          end

          def absolute_pos
            [@sprite.absolute_x + @x, @sprite.absolute_y + @y]
          end

          def collide?(other)
            case other
            when Point
              other.collide?(self)
            when Circle
              case [self.ellipse?, other.ellipse?]
              when [true, true]
                polygons_collide?(transformed_circle, other.transformed_circle)
              when [true, false]
                polygon_circle_collide?(transformed_circle, other.absolute_pos, other.r)
              when [false, true]
                polygon_circle_collide?(other.transformed_circle, absolute_pos, @r)
              when [false, false]
                circles_collide?(absolute_pos, @r, other.absolute_pos, other.r)
              end
            when Rect, Triangle
              if ellipse?
                polygons_collide?(transformed_circle, other.absolute_poss)
              else
                polygon_circle_collide?(other.absolute_poss, absolute_pos, @r)
              end
            end
          end

          # SAT-based collision detection: polygon vs circle
          def polygon_circle_collide?(polygon, circle_center, radius)
            _js_runner.polygon_circle_collide?(polygon, circle_center, radius)
          end

          def circles_collide?(center1, radius1, center2, radius2)
            dist_sq = distance_squared(center1, center2)
            radius_sum = radius1 + radius2
            dist_sq <= radius_sum * radius_sum
          end

          def aabb
            if ellipse?
              calculate_aabb(transformed_circle)
            else
              cx, cy = absolute_pos
              [cx - @r, cy - @r, cx + @r, cy + @r]
            end
          end

          # Approximate the circle as a polygon
          def transformed_circle(segments = 16)
            _js_runner.transformed_circle(@x, @y, @r, segments, @sprite.absolute_x, @sprite.absolute_y,
                                          @sprite.collision_sync, @sprite.center_x, @sprite.center_y,
                                          @sprite.scale_x, @sprite.scale_y, @sprite.angle).to_a.map { |p| p.to_a.map(&:to_i) }
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
            transformed([[@x1, @y1], [@x2, @y1], [@x2, @y2], [@x1, @y2]])
          end

          def aabb
            calculate_aabb(absolute_poss)
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
            transformed(@poss)
          end

          def aabb
            calculate_aabb(absolute_poss)
          end
        end
      end

      module ClassMethods
        def _js_runner
          @runner ||= JS.global[:window][:DXRubyWasmCollision]
        end

        def check(o_sprites, d_sprites, shot = :shot, hit = :hit)
          res = false
          o_sprites = Array(o_sprites).select { |s| s.is_a?(Sprite) && s.collidable? }
          d_sprites = Array(d_sprites).select { |s| s.is_a?(Sprite) && s.collidable? }

          return false if o_sprites.empty? || d_sprites.empty?

          # NOTE: The cell size for the spatial grid is fixed at 64.
          # This may not be optimal for all sprite sizes and could be a subject
          # for future performance tuning.
          cell_size = 64
          grid = SpaceGrid.new(cell_size, cell_size)
          (o_sprites + d_sprites).each { |s| grid.add(s) }

          discards = []

          o_sprites.each do |o_sprite|
            next if discards.include?(o_sprite)

            candidates = grid.get_candidates(o_sprite)
            target_sprites = candidates & d_sprites

            target_sprites.each do |d_sprite|
              next if discards.include?(d_sprite)

              if o_sprite === d_sprite
                res = true
                discard = false
                if shot && o_sprite.respond_to?(shot)
                  discard = (o_sprite.send(shot, d_sprite) == :discard)
                end
                if hit && d_sprite.respond_to?(hit)
                  discard = (d_sprite.send(hit, o_sprite) == :discard)
                end
                if discard
                  discards << o_sprite
                  discards << d_sprite
                  break
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

        # Broad phase: AABB collision check
        return false unless aabb_collide?(@hitbox.aabb, sprite.hitbox.aabb)

        # Narrow phase: Detailed collision check
        @hitbox.collide?(sprite.hitbox)
      end

      def _js_runner
        self.class._js_runner
      end

      def aabb_collide?(box1, box2)
        _js_runner.aabb_collide?(box1, box2)
      end
    end
  end
end
