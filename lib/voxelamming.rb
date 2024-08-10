# frozen_string_literal: true

require_relative "voxelamming/version"
require 'json'
require 'faye/websocket'
require 'eventmachine'
require 'date'
require_relative 'matrix_util'
require 'csv'

module Voxelamming
  class Error < StandardError; end

  # test
  def self.greet(name)
    puts "Hello, #{name}! I'm Ruby!"
  end

  # Main process
  class BuildBox
    @@texture_names = ["grass", "stone", "dirt", "planks", "bricks"]
    @@model_names = ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto", "Sun",
                     "Moon", "ToyBiplane", "ToyCar", "Drummer", "Robot", "ToyRocket", "RocketToy1", "RocketToy2", "Skull"]

    def initialize(room_name)
      @room_name = room_name
      @is_allowed_matrix = 0
      @saved_matrices = []
      @node_transform = [0, 0, 0, 0, 0, 0]
      @matrix_transform = [0, 0, 0, 0, 0, 0]
      @frame_transforms = []
      @global_animation = [0, 0, 0, 0, 0, 0, 1, 0]
      @animation = [0, 0, 0, 0, 0, 0, 1, 0]
      @boxes = []
      @frames = []
      @sentence = []
      @lights = []
      @commands = []
      @models = []
      @model_moves = []
      @size = 1
      @shape = 'box'
      @is_metallic = 0
      @roughness = 0.5
      @is_allowed_float = 0
      @build_interval = 0.01
      @is_framing = false
      @frame_id = 0
    end

    def clear_data
      @is_allowed_matrix = 0
      @saved_matrices = []
      @node_transform = [0, 0, 0, 0, 0, 0]
      @matrix_transform = [0, 0, 0, 0, 0, 0]
      @frame_transforms = []
      @global_animation = [0, 0, 0, 0, 0, 0, 1, 0]
      @animation = [0, 0, 0, 0, 0, 0, 1, 0]
      @boxes = []
      @frames = []
      @sentence = []
      @lights = []
      @commands = []
      @models = []
      @model_moves = []
      @size = 1
      @shape = 'box'
      @is_metallic = 0
      @roughness = 0.5
      @is_allowed_float = 0
      @build_interval = 0.01
      @is_framing = false
      @frame_id = 0
    end

    def set_frame_fps(fps = 2)
      @commands << "fps #{fps}"
    end

    def set_frame_repeats(repeats = 10)
      @commands << "repeats #{repeats}"
    end

    def frame_in
      @is_framing = true
    end

    def frame_out
      @is_framing = false
      @frame_id += 1
    end

    def push_matrix
      @is_allowed_matrix += 1
      @saved_matrices.push(@matrix_transform)
    end

    def pop_matrix
      @is_allowed_matrix -= 1
      @matrix_transform = @saved_matrices.pop
    end

    def transform(x, y, z, pitch: 0, yaw: 0, roll: 0)
      if @is_allowed_matrix > 0
        # 移動用のマトリックスを計算する
        matrix = @saved_matrices.last
        puts "before matrix: #{matrix}"
        base_position = matrix[0..2]

        if matrix.length == 6
          base_rotation_matrix = get_rotation_matrix(matrix[3], matrix[4], matrix[5])
        else
          base_rotation_matrix = [matrix[3..5], matrix[6..8], matrix[9..11]]
        end

        # Compute the new position after transform
        add_x, add_y, add_z = transform_point_by_rotation_matrix([x, y, z], transpose_3x3(base_rotation_matrix))
        x, y, z = add_vectors(base_position, [add_x, add_y, add_z])
        x, y, z = round_numbers([x, y, z])

        # Compute the rotation after transform
        translate_rotation_matrix = get_rotation_matrix(-pitch, -yaw, -roll)
        rotate_matrix = matrix_multiply(translate_rotation_matrix, base_rotation_matrix)
        @matrix_transform = [x, y, z, *rotate_matrix[0], *rotate_matrix[1], *rotate_matrix[2]]
      else
        x, y, z = round_numbers([x, y, z])

        if @is_framing
          @frame_transforms.append([x, y, z, pitch, yaw, roll, @frame_id])
        else
          @node_transform = [x, y, z, pitch, yaw, roll]
        end
      end
    end

    def create_box(x, y, z, r: 1, g: 1, b: 1, alpha: 1, texture: '')
      if @is_allowed_matrix > 0
        # 移動用のマトリックスにより位置を計算する
        matrix = @matrix_transform
        base_position = matrix[0..2]

        if matrix.length == 6
          base_rotation_matrix = get_rotation_matrix(matrix[3], matrix[4], matrix[5])
        else
          base_rotation_matrix = [matrix[3..5], matrix[6..8], matrix[9..11]]
        end

        # Compute the new position after transform
        add_x, add_y, add_z = transform_point_by_rotation_matrix([x, y, z], transpose_3x3(base_rotation_matrix))
        x, y, z = add_vectors(base_position, [add_x, add_y, add_z])
      end

      x, y, z = round_numbers([x, y, z])
      r, g, b, alpha = round_two_decimals([r, g, b, alpha])

      # 重ねておくことを防止
      remove_box(x, y, z)
      if !@@texture_names.include?(texture)
        texture_id = -1
      else
        texture_id = @@texture_names.index(texture)
      end

      if @is_framing
        @frames.append([x, y, z, r, g, b, alpha, texture_id, @frame_id])
      else
        @boxes.append([x, y, z, r, g, b, alpha, texture_id])
      end
    end

    def remove_box(x, y, z)
      x, y, z = round_numbers([x, y, z])

      if @is_framing
        @frames.reject! { |frame| frame[0] == x && frame[1] == y && frame[2] == z && frame[8] == @frame_id }
      else
        @boxes.reject! { |box| box[0] == x && box[1] == y && box[2] == z }
      end
    end

    def animate_global(x, y, z, pitch: 0, yaw: 0, roll: 0, scale: 1, interval: 10)
      x, y, z = round_numbers([x, y, z])
      @global_animation = [x, y, z, pitch, yaw, roll, scale, interval]
    end

    def animate(x, y, z, pitch: 0, yaw: 0, roll: 0, scale: 1, interval: 10)
      x, y, z = round_numbers([x, y, z])
      @animation = [x, y, z, pitch, yaw, roll, scale, interval]
    end

    def set_box_size(box_size)
      @size = box_size
    end

    def set_build_interval(interval)
      @build_interval = interval
    end

    def write_sentence(sentence, x, y, z, r: 1, g: 1, b: 1, alpha: 1)
      x, y, z = round_numbers([x, y, z]).map(&:to_s)
      r, g, b, alpha = round_two_decimals([r, g, b, alpha])
      r, g, b, alpha =  [r, g, b, alpha].map(&:floor).map(&:to_s)
      @sentence = [sentence, x, y, z, r, g, b, alpha]
    end

    def set_light(x, y, z, r: 1, g: 1, b: 1, alpha: 1, intensity: 1000, interval: 1, light_type: 'point')
      x, y, z = round_numbers([x, y, z])
      r, g, b, alpha = round_two_decimals([r, g, b, alpha])

      if light_type == 'point'
        light_type = 1
      elsif light_type == 'spot'
        light_type = 2
      elsif light_type == 'directional'
        light_type = 3
      else
        light_type = 1
      end
      @lights << [x, y, z, r, g, b, alpha, intensity, interval, light_type]
    end

    def set_command(command)
      @commands << command

      if command == 'float'
        @is_allowed_float = 1
      end
    end

    def draw_line(x1, y1, z1, x2, y2, z2, r: 1, g: 1, b: 1, alpha: 1)
      x1, y1, z1, x2, y2, z2 = [x1, y1, z1, x2, y2, z2].map(&:floor)
      diff_x = x2 - x1
      diff_y = y2 - y1
      diff_z = z2 - z1
      max_length = [diff_x.abs, diff_y.abs, diff_z.abs].max

      return false if diff_x == 0 && diff_y == 0 && diff_z == 0

      if diff_x.abs == max_length
        if x2 > x1
          (x1..x2).each do |x|
            y = y1 + (x - x1) * diff_y.to_f / diff_x
            z = z1 + (x - x1) * diff_z.to_f / diff_x
            create_box(x, y, z, r: r, g: g, b: b, alpha: alpha)
          end
        else
          x1.downto(x2 + 1) do |x|
            y = y1 + (x - x1) * diff_y.to_f / diff_x
            z = z1 + (x - x1) * diff_z.to_f / diff_x
            create_box(x, y, z, r: r, g: g, b: b, alpha: alpha)
          end
        end
      elsif diff_y.abs == max_length
        if y2 > y1
          (y1..y2).each do |y|
            x = x1 + (y - y1) * diff_x.to_f / diff_y
            z = z1 + (y - y1) * diff_z.to_f / diff_y
            create_box(x, y, z, r: r, g: g, b: b, alpha: alpha)
          end
        else
          y1.downto(y2 + 1) do |y|
            x = x1 + (y - y1) * diff_x.to_f / diff_y
            z = z1 + (y - y1) * diff_z.to_f / diff_y
            create_box(x, y, z, r: r, g: g, b: b, alpha: alpha)
          end
        end
      elsif diff_z.abs == max_length
        if z2 > z1
          (z1..z2).each do |z|
            x = x1 + (z - z1) * diff_x.to_f / diff_z
            y = y1 + (z - z1) * diff_y.to_f / diff_z
            create_box(x, y, z, r: r, g: g, b: b, alpha: alpha)
          end
        else
          z1.downto(z2 + 1) do |z|
            x = x1 + (z - z1) * diff_x.to_f / diff_z
            y = y1 + (z - z1) * diff_y.to_f / diff_z
            create_box(x, y, z, r: r, g: g, b: b, alpha: alpha)
          end
        end
      end
    end

    def change_shape(shape)
      @shape = shape
    end

    def change_material(is_metallic: false, roughness: 0.5)
      @is_metallic = is_metallic ? 1 : 0
      @roughness = roughness
    end

    def create_model(model_name, x: 0, y: 0, z: 0, pitch: 0, yaw: 0, roll: 0, scale: 1, entity_name: '')
      if @@model_names.include?(model_name)
        x, y, z, pitch, yaw, roll, scale = round_two_decimals([x, y, z, pitch, yaw, roll, scale])
        x, y, z, pitch, yaw, roll, scale = [x, y, z, pitch, yaw, roll, scale].map(&:to_s)

        @models << [model_name, x, y, z, pitch, yaw, roll, scale, entity_name]
      else
        puts "No model name: #{model_name}"
      end
    end

    def move_model(entity_name, x: 0, y: 0, z: 0, pitch: 0, yaw: 0, roll: 0, scale: 1)
      x, y, z, pitch, yaw, roll, scale = round_two_decimals([x, y, z, pitch, yaw, roll, scale])
      x, y, z, pitch, yaw, roll, scale = [x, y, z, pitch, yaw, roll, scale].map(&:to_s)

      @model_moves << [entity_name, x, y, z, pitch, yaw, roll, scale]
    end


    def send_data(name: '')
      puts 'send_data'
      now = DateTime.now
      data_to_send = {
        "nodeTransform": @node_transform,
        "frameTransforms": @frame_transforms,
        "globalAnimation": @global_animation,
        "animation": @animation,
        "boxes": @boxes,
        "frames": @frames,
        "sentence": @sentence,
        "lights": @lights,
        "commands": @commands,
        "models": @models,
        "modelMoves": @model_moves,
        "size": @size,
        "shape": @shape,
        "interval": @build_interval,
        "isMetallic": @is_metallic,
        "roughness": @roughness,
        "isAllowedFloat": @is_allowed_float,
        "name": name,
        "date": now.to_s
      }.to_json

      EM.run do
        ws = Faye::WebSocket::Client.new('wss://websocket.voxelamming.com')

        ws.on :open do |_event|
          p [:open]
          puts 'WebSocket connection open'
          ws.send(@room_name)
          puts "Joined room: #{@room_name}"
          ws.send(data_to_send)
          puts data_to_send
          puts 'Sent data to server'

          EM.add_timer(1) do
            ws.close
            EM.stop
          end
        end

        ws.on :error do |event|
          puts "WebSocket error: #{event.message}"
          EM.stop
        end

        ws.on :close do |_event|
          puts 'WebSocket connection closed'
          EM.stop
        end
      end
    end

    def round_numbers(num_list)
      if @is_allowed_float == 1
        round_two_decimals(num_list)
      else
        num_list.map { |val| val.round(1).floor }
      end
    end

    def round_two_decimals(num_list)
      num_list.map { |val| val.round(2) }
    end
  end

  # Turtle graphics
  class Turtle
    include Math

    def initialize(build_box)
      @build_box = build_box
      @x = 0
      @y = 0
      @z = 0
      @polar_theta = 90
      @polar_phi = 0
      @drawable = true
      @color = [0, 0, 0, 1]
      @size = 1
    end

    def forward(length)
      z = @z + length * sin(radians(@polar_theta)) * cos(radians(@polar_phi))
      x = @x + length * sin(radians(@polar_theta)) * sin(radians(@polar_phi))
      y = @y + length * cos(radians(@polar_theta))
      x, y, z = x.round(3), y.round(3), z.round(3)

      if @drawable
        @build_box.draw_line(@x, @y, @z, x, y, z, r: @color[0], g: @color[1], b: @color[2])
      end

      @x = x
      @y = y
      @z = z
    end

    def backward(length)
      forward(-length)
    end

    def up(degree)
      @polar_theta -= degree
    end

    def down(degree)
      @polar_theta += degree
    end

    def right(degree)
      @polar_phi -= degree
    end

    def left(degree)
      @polar_phi += degree
    end

    def set_color(r, g, b, alpha = 1)
      @color = [r, g, b, alpha]
    end

    def pen_down
      @drawable = true
    end

    def pen_up
      @drawable = false
    end

    def set_pos(x, y, z)
      @x = x
      @y = y
      @z = z
    end

    def reset
      @x = 0
      @y = 0
      @z = 0
      @polar_theta = 90
      @polar_phi = 0
      @drawable = true
      @color = [0, 0, 0, 1]
      @size = 1
    end

    private

    def radians(degrees)
      degrees * Math::PI / 180
    end
  end

  # Make model
  def self.get_boxes_from_ply(ply_file)
    box_positions = Set.new
    File.open(ply_file, 'r') do |f|
      lines = f.read
      lines = lines.gsub("\r\n", "\n")
      lines = lines.strip
      positions = lines.split("\n").select { |ln| self.is_included_six_numbers(ln) }.map { |ln| ln.split.map(&:to_f) }

      number_of_faces = positions.length / 4
      (0...number_of_faces).each do |i|
        vertex1 = positions[i * 4]
        vertex2 = positions[i * 4 + 1]
        vertex3 = positions[i * 4 + 2]
        vertex4 = positions[i * 4 + 3] # no need
        x = [vertex1[0], vertex2[0], vertex3[0]].min
        y = [vertex1[1], vertex2[1], vertex3[1]].min
        z = [vertex1[2], vertex2[2], vertex3[2]].min
        r = vertex1[3] / 255.0
        g = vertex1[4] / 255.0
        b = vertex1[5] / 255.0
        alpha = 1

        # ボックスを置く方向を解析
        if vertex1[0] == vertex2[0] && vertex2[0] == vertex3[0] # y-z plane
          step = [vertex1[1], vertex2[1], vertex3[1]].max - y
          x -= step if vertex1[1] != vertex2[1]
        elsif vertex1[1] == vertex2[1] && vertex2[1] == vertex3[1] # z-x plane
          step = [vertex1[2], vertex2[2], vertex3[2]].max - z
          y -= step if vertex1[2] != vertex2[2]
        else # x-y plane
          step = [vertex1[0], vertex2[0], vertex3[0]].max - x
          z -= step if vertex1[0] != vertex2[0]
        end

        # minimum unit: 0.1
        position_x = (x * 10.0 / step).round / 10.0
        position_y = (y * 10.0 / step).round / 10.0
        position_z = (z * 10.0 / step).round / 10.0
        box_positions.add([position_x, position_z, -position_y, r, g, b, alpha])
      end
    end

    box_positions
  end

  def self.is_included_six_numbers(line)
    line_list = line.split
    return false if line_list.length != 6

    line_list.all? { |num| Float(num) rescue false }
  end

  # Map
  def self.get_map_data_from_csv(csv_file, height_scale, column_num = 257, row_num = 257)
    # csvファイルから地図データを読み込み
    heights = []

    CSV.foreach(csv_file) do |row|
      for h in row
        h = h.to_f
        h = h != 0 ? (h * height_scale).floor : -1
        heights << h
      end
    end
    #   puts "heights: #{heights}"

    max_height = heights.max.floor
    box_positions = (0...row_num).map { |i| heights[i * column_num, column_num] }
    puts "max_height: #{max_height}"
    #   puts "box_positions: #{box_positions}"
    { 'boxes' => box_positions, 'max_height' => max_height }
  end

  def self.get_box_color(height, max_height, high_color, low_color)
    # 高さによって色を変える
    r = (high_color[0] - low_color[0]) * height * 1.0 / max_height + low_color[0]
    g = (high_color[1] - low_color[1]) * height * 1.0 / max_height + low_color[1]
    b = (high_color[2] - low_color[2]) * height * 1.0 / max_height + low_color[2]

    [r, g, b]
  end
end
