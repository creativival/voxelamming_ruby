# Voxelamming

This Ruby package converts Python code into JSON format and sends it to the Voxelamming app using WebSockets, allowing users to create 3D voxel models by writing Ruby scripts.

## What's Voxelamming?

<p align="center"><img src="https://creativival.github.io/voxelamming/image/voxelamming_icon.png" alt="Voxelamming Logo" width="200"/></p>

Voxelamming is an AR programming learning app. Even programming beginners can learn programming visually and enjoyably. Voxelamming supports iPhones and iPads with iOS 16 or later, and Apple Vision Pro.

## Resources

* **Homepage:** https://creativival.github.io/voxelamming/index.en
* **Samples:** https://github.com/creativival/voxelamming/tree/main/sample/ruby


## Installation

```bash
gem install voxelamming
```

## Usage

```ruby
require 'voxelamming'

room_name = '1000'
vox = Voxelamming::VoxelammingManager.new(room_name)

vox.set_box_size(0.5)
vox.set_build_interval(0.01)

for i in 0...100
  vox.create_box(-1, i, 0, r: 0, g: 1, b: 1)
  vox.create_box(0, i, 0, r: 1, g: 0, b: 0)
  vox.create_box(1, i, 0, r: 1, g: 1, b: 0)
  vox.create_box(2, i, 0, r: 0, g: 1, b: 1)
end

for i in 0...50
  vox.remove_box(0, i * 2, 0)
  vox.remove_box(1, i * 2 + 1, 0)
end

vox.send_data
```

This code snippet demonstrates a simple example where a red voxel is created at a specific location. You can use various functions provided by the `VoxelammingManager` class to build more complex models.

#### Method description

| Method name | Description | Arguments |
|---|---|---|
| `set_room_name(room_name)` | Sets the room name for communicating with the device. | `room_name`: Room name (string) |
| `set_box_size(size)` | Sets the size of the voxel (default: 1.0). | `size`: Size (float) |
| `set_build_interval(interval)` | Sets the placement interval of the voxels (default: 0.01 seconds). | `interval`: Interval (float) |
| `change_shape(shape)` | Changes the shape of the voxel. | `shape`: Shape ("box", "square", "plane") |
| `change_material(is_metallic, roughness)` | Changes the material of the voxel. | `is_metallic`: Whether to make it metallic (boolean), `roughness`: Roughness (float) |
| `create_box(x, y, z, r, g, b, alpha)` | Places a voxel. | `x`, `y`, `z`: Position (float), `r`, `g`, `b`, `alpha`: Color (float, 0-1) |
| `create_box(x, y, z, texture)` | Places a voxel with texture. | `x`, `y`, `z`: Position (float), `texture`: Texture name (string) |
| `remove_box(x, y, z)` | Removes a voxel. | `x`, `y`, `z`: Position (float) |
| `write_sentence(sentence, x, y, z, r, g, b, alpha)` | Draws a string with voxels. | `sentence`: String (string), `x`, `y`, `z`: Position (float), `r`, `g`, `b`, `alpha`: Color (float, 0-1) |
| `set_light(x, y, z, r, g, b, alpha, intensity, interval, light_type)` | Places a light. | `x`, `y`, `z`: Position (float), `r`, `g`, `b`, `alpha`: Color (float, 0-1), `intensity`: Intensity (float), `interval`: Blinking interval (float), `light_type`: Type of light ("point", "spot", "directional") |
| `set_command(command)` | Executes a command. | `command`: Command ("axis", "japaneseCastle", "float", "liteRender") |
| `draw_line(x1, y1, z1, x2, y2, z2, r, g, b, alpha)` | Draws a line between two points. | `x1`, `y1`, `z1`: Starting point (float), `x2`, `y2`, `z2`: Ending point (float), `r`, `g`, `b`, `alpha`: Color (float, 0-1) |
| `send_data(name)` | Sends voxel data to the device; if the name argument is set, the voxel data can be stored and reproduced as history. | |
| `clear_data()` | Initializes voxel data. | |
| `transform(x, y, z, pitch, yaw, roll)` | Moves and rotates the coordinate system of the voxel. | `x`, `y`, `z`: Translation amount (float), `pitch`, `yaw`, `roll`: Rotation amount (float) |
| `animate(x, y, z, pitch, yaw, roll, scale, interval)` | Animates a voxel. | `x`, `y`, `z`: Translation amount (float), `pitch`, `yaw`, `roll`: Rotation amount (float), `scale`: Scale (float), `interval`: Interval (float) |
| `animate_global(x, y, z, pitch, yaw, roll, scale, interval)` | Animates all voxels. | `x`, `y`, `z`: Translation amount (float), `pitch`, `yaw`, `roll`: Rotation amount (float), `scale`: Scale (float), `interval`: Interval (float) |
| `push_matrix()` | Saves the current coordinate system to the stack. | |
| `pop_matrix()` | Restores the coordinate system from the stack. | |
| `frame_in()` | Starts recording a frame. | |
| `frame_out()` | Ends recording a frame. | |
| `set_frame_fps(fps)` | Sets the frame rate (default: 2). | `fps`: Frame rate (int) |
| `set_frame_repeats(repeats)` | Sets the number of frame repetitions (default: 10). | `repeats`: Number of repetitions (int) |
| Game Method Name                                                                              | Description | Arguments                                                                                                                                                            |
| `set_game_screen(width, height, angle=90, r=1, g=1, b=0, alpha=0.5)`                | Sets the game screen size. | `width`, `height`: screen size (float), `angle`: angle (float), `r`, `g`, `b`, `alpha`: color (float, 0-1)                                                            |
| `set_game_score(score)`                                                                  | Sets the game score. | `score`: game score (int)                                                                                                                                            |
| `send_game_over()`                                                                       | Triggers game over. |                                                                                                                                                                     |
| `create_sprite(sprite_name, color_list, x, y, direction=90, scale=1, visible=True)`      | Creates a sprite. | `sprite_name`: sprite name (string), `color_list`: dot color data (string), `x`, `y`: position (float), `direction`: angle (float), `scale`: scale (float), `visible`: visibility (boolean) |
| `move_sprite(sprite_name, x, y, direction=90, scale=1, visible=True)`                    | Moves a sprite. | `sprite_name`: sprite name (string), `x`, `y`: position (float), `direction`: angle (float), `scale`: scale (float), `visible`: visibility (boolean)                                  |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/creativival/voxelamming_ruby_gem. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/voxelamming_ruby_gem/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Voxelamming project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/voxelamming_ruby_gem/blob/master/CODE_OF_CONDUCT.md).
