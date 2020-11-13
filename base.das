options remove_unused_symbols = false
module base
require math

let
  DEG_TO_RAD = PI / 180.
  RAD_TO_DEG = 180. / PI

[generic]
def deg_to_rad(val)
  return val * DEG_TO_RAD

[generic]
def rad_to_deg(val)
  return val * RAD_TO_DEG

[generic]
def square(x)
  return x * x

[generic]
def abs(val : int) : int
  return val >= 0 ? val : -val

[generic]
def approach(from, to:auto(algebraic); dt: float; viscosity: float)
  return viscosity < 1e-9 ? to : from + (1.0 - exp(-dt / viscosity)) * (to - from)

// move_to version for float
[generic]
def move_to_scalar(from, to, dt, vel: float)
  let d = vel * dt
  if abs(from - to) < d
    return to

  if to < from
    return from - d
  return from + d

// move_to version for vector types
[generic]
def move_to(from, to: auto(algebraic); dt, vel: float)
  let d = vel * dt
  let dir = to - from
  let dlen = length(dir)
  if dlen <= d
    return to
  return from + (dir / dlen) * d

[generic]
def invsqrt(x)
  return rcp(sqrt(x))

[generic]
def safeinvsqrt(x)
  return x > 0.0 ? invsqrt(x) : 1.0

[generic]
def safediv(a; b)
  return b > FLT_EPSILON ? a / b : (b < -FLT_EPSILON ? a / b : 0.)

[generic]
def safeinv(x)
  return safediv(1., x)
