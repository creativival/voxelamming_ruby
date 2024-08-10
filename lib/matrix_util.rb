include Math

def get_rotation_matrix(pitch, yaw, roll)
  pitch, yaw, roll = [pitch, yaw, roll].map { |angle| degrees_to_radians(angle) }
  # Pitch (Rotation around X-axis)
  rx = [
    [1, 0, 0],
    [0, cos(pitch), -sin(pitch)],
    [0, sin(pitch), cos(pitch)]
  ]

  # Yaw (Rotation around Y-axis)
  ry = [
    [cos(yaw), 0, sin(yaw)],
    [0, 1, 0],
    [-sin(yaw), 0, cos(yaw)]
  ]

  # Roll (Rotation around Z-axis)
  rz = [
    [cos(roll), -sin(roll), 0],
    [sin(roll), cos(roll), 0],
    [0, 0, 1]
  ]

  # Multiplication of matrices in the order Rx * Rz * Ry
  r = matrix_multiply(rx, matrix_multiply(rz, ry))
  return r
end

def matrix_multiply(a, b)
  result = Array.new(3) { Array.new(3, 0) }
  for i in 0...3
    for j in 0...3
      for k in 0...3
        result[i][j] += a[i][k] * b[k][j]
      end
    end
  end
  return result
end

def transform_point_by_rotation_matrix(point, r)
  x, y, z = point
  x_new = r[0][0] * x + r[0][1] * y + r[0][2] * z
  y_new = r[1][0] * x + r[1][1] * y + r[1][2] * z
  z_new = r[2][0] * x + r[2][1] * y + r[2][2] * z
  return [x_new, y_new, z_new]
end

def add_vectors(vector1, vector2)
  vector1.zip(vector2).map { |v1, v2| v1 + v2 }
end

def transpose_3x3(matrix)
  return [
    [matrix[0][0], matrix[1][0], matrix[2][0]],
    [matrix[0][1], matrix[1][1], matrix[2][1]],
    [matrix[0][2], matrix[1][2], matrix[2][2]]
  ]
end

def degrees_to_radians(degrees)
  degrees * Math::PI / 180.0
end
