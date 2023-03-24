require "time"
# Tabulated values for March equinox.
# Values for 2022-2028 from Wikipedia:
# https://en.wikipedia.org/wiki/March_equinox (version from 2022-09-15). Time
# values given there are in UT, and we use them here as UTC, as the difference
# is less than 1 second, and the equinox times are given with 1 minute accuracy
# only anyway.
# Values for years 2029-2033 from https://aa.usno.navy.mil/data/Earth_Seasons.
March_Equinoxes = [
  Time.parse("2022-03-20 15:33 UTC"),
  Time.parse("2023-03-20 21:25 UTC"),
  Time.parse("2024-03-20 03:07 UTC"),
  Time.parse("2025-03-20 09:02 UTC"),
  Time.parse("2026-03-20 14:46 UTC"),
  Time.parse("2027-03-20 20:25 UTC"),
  Time.parse("2028-03-20 02:17 UTC"),
  Time.parse("2029-03-20 08:02 UTC"),
  Time.parse("2030-03-20 13:52 UTC"),
  Time.parse("2031-03-20 19:41 UTC"),
  Time.parse("2032-03-20 01:22 UTC"),
  Time.parse("2033-03-20 07:22 UTC")
]
# Tabulated values for June solstice taken from same sources as the
# March equinoxes:
June_Solstices = [
  Time.parse("2022-06-21 09:14 UTC"),
  Time.parse("2023-06-21 14:58 UTC"),
  Time.parse("2024-06-20 20:51 UTC"),
  Time.parse("2025-06-21 02:42 UTC"),
  Time.parse("2026-06-21 08:25 UTC"),
  Time.parse("2027-06-21 14:11 UTC"),
  Time.parse("2028-06-20 20:02 UTC"),
  Time.parse("2029-06-21 01:48 UTC"),
  Time.parse("2030-06-21 07:31 UTC"),
  Time.parse("2031-06-21 13:17 UTC"),
  Time.parse("2032-06-20 19:09 UTC"),
  Time.parse("2033-06-21 01:01 UTC")
]
# Tabulated values for September equinox taken from same sources as
# the March equinoxes:
September_Equinoxes = [
  Time.parse("2022-09-23 01:04 UTC"),
  Time.parse("2023-09-23 06:50 UTC"),
  Time.parse("2024-09-22 12:44 UTC"),
  Time.parse("2025-09-22 18:20 UTC"),
  Time.parse("2026-09-23 00:06 UTC"),
  Time.parse("2027-09-23 06:02 UTC"),
  Time.parse("2028-09-22 11:45 UTC"),
  Time.parse("2029-09-22 17:38 UTC"),
  Time.parse("2030-09-22 23:27 UTC"),
  Time.parse("2031-09-23 05:15 UTC"),
  Time.parse("2032-09-22 11:11 UTC"),
  Time.parse("2033-09-22 16:51 UTC")
]
# Tabulated values for December solstice taken from same sources as
# the March equinoxes:
December_Solstices = [
  Time.parse("2022-12-21 21:48 UTC"),
  Time.parse("2023-12-22 03:28 UTC"),
  Time.parse("2024-12-21 09:20 UTC"),
  Time.parse("2025-12-21 15:03 UTC"),
  Time.parse("2026-12-21 20:50 UTC"),
  Time.parse("2027-12-22 02:43 UTC"),
  Time.parse("2028-12-21 08:20 UTC"),
  Time.parse("2029-12-21 14:14 UTC"),
  Time.parse("2030-12-21 20:09 UTC"),
  Time.parse("2031-12-22 01:55 UTC"),
  Time.parse("2032-12-21 07:56 UTC"),
  Time.parse("2033-12-21 13:46 UTC")
]

# For a given time, find the two equinox / solstice dates that surround it,
# and return them as the first two elements of an array. The first element is
# the the time of the astronomical event that is earlier than or equal to the
# given time, and the second element is the following event approximately three
# months later.
# The time parameter may be in any time zone.
# Raises an exception if the given time is before the first March equinox in
# our table, or equal to or after the last December solstice in our table.
# A third array element is returned: 0.0 if the first array element is a March
# equinox, 0.25 if the first element is a June solstice, 0.5 for a September
# equinox, and 0.75 for a December solstice.
def find_surrounding_seasonal_dates(time)
  throw :not_found if time<March_Equinoxes[0] || time>=December_Solstices[-1]

  combined_dates = [March_Equinoxes, June_Solstices, September_Equinoxes,
    December_Solstices].transpose.flatten

  return get_surrounding_elements(combined_dates, time, 4)
end

# Find the two elements in the given sorted array that surround the given
# value.
# The first element is the greatest element in array that is still <= value,
# and the second element is the subsequent element in array.
# Raises an exception if the given value is smaller than the first element
# in the array, >= array.last, or if the array is empty.
# If the modulo parameter is given, then the returned array contains a
# third element with value (index of first element % modulo) / modulo.to_f.
def get_surrounding_elements(array, value, modulo = nil)
  throw :not_found if array.empty? || value < array[0] || value >= array[-1]

  index = array.bsearch_index { |element| element > value } - 1
  return array[index,2] + (modulo ? [(index % modulo)  /  modulo.to_f] : [])
end

# For the given date and time, compute how far we are into the solar year
# which starts at the March equinox. The result is a number between 0 and 1.
# The result is 0 at the March equinox, 0.25 at the June solstice, 0.5 at the
# September equinox, and 0.75 at the December solstice.
# The time may be in any time zone.
def solar_year_fraction(time)
  t1, t2, offset = find_surrounding_seasonal_dates(time)
  fraction = offset + (time - t1) / (t2 - t1) / 4
  return fraction
end

# Checks if the sun when in zenith over sun_location is visible from location.
# Both sun_location and location are arrays containing latitude and longitude
# in degrees.
# Returns true if the sun is above the horizon, false otherwise.
def visible?(sun_location, location)
  return cos_of_angle_between(sun_location, location) >= 0
end

# Change direction of a solar module's normal vector by tilt and bearing.
# Tilt is in degrees, 0 means the module lies flat on earth's surface, 90
# means vertical, like on a fence or wall, with the module facing exactly
# the horizon.
# Bearing is in degrees, 0 means the module faces north, 90 means east,
# 180 means south, ...
# Position is an array containing latitude and longitude in degrees.
# Returns the position on earth where the surface has the same orientation
# as the normal vector of the tilted and rotated surface.
def orient(position, tilt, bearing)
  return position if tilt == 0
  if (bearing % 180 == 0)
    position = [position[0] + tilt * (-1)**(bearing/180), position[1]]
    if (position[0] > 90 && position[0] <= 270)
      position[0] = 180 - position[0]
      position[1] += (position[1]<0) ? 180 : -180
    elsif (position[0] < -90 && position[0] >= -270)
      position[0] = -180 - position[0]
      position[1] += (position[1]<0) ? 180 : -180  
    end
    # if position is normalized, return it
    if (position[0] >= -90 && position[0] <= 90 && position[1] >= -180 && position[1] <= 180)
      return position
    end
    # otherwise normalize it by converting to cartesian coordinates and back
    tilt,bearing = 0,0
    puts ('Normalizing position %p' % [position])
  end
  lat, lon = *position
  elevation = lat + tilt
  return rotate([elevation,lon], position, bearing)
end

# Convert latitude and longitude in degrees to a unit vector.
# Returns an array containing x, y, and z coordinates.
# Positive x passes through [0,0], positive y passes through [0,90],
# positive z passes through [90,0] (North Pole)
def latlon2xyz(lat, lon)
  lat *= Math::PI / 180
  lon *= Math::PI / 180
  return [
    Math.cos(lat) * Math.cos(lon),
    Math.cos(lat) * Math.sin(lon),
    Math.sin(lat)
  ].map{|x| x.round(15)}
end

# Convert a unit vector to latitude and longitude in degrees.
# Returns an array containing latitude and longitude.
def xyz2latlon(x, y, z)
  lat = Math.asin(z) * 180 / Math::PI
  lon = Math.atan2(y, x) * 180 / Math::PI
  return [lat, lon].map{|w| w.round(12)}
end

require "matrix"

# Rotate location around axis by angle degrees.
# Both location and axis are arrays containing [latitude,longitute] in degrees.
# The rotation is in degrees, positive values rotate counter-clockwise when
# looking from space towards the earth's surface where axis emerges.
def rotate(location, axis, angle)
  # First we need to convert the lat/lon coordinates to xyz coordinates.
  location = Vector[*latlon2xyz(*location)]
  axis = Vector[*latlon2xyz(*axis)]
  angle = angle * Math::PI / 180

  # Use Rodrigues' rotation formula to rotate the vector.
  # http://en.wikipedia.org/wiki/Rodrigues%27_rotation_formula
  v = location * Math.cos(angle) -
      axis.cross_product(location) * Math.sin(angle) +
      axis * axis.dot(location) * (1 - Math.cos(angle))
  return xyz2latlon(*v)
end

# Computes latitude of the place on earth where the sun is in zenith at the
# given time.
# The time may be in any time zone.
# Returns the latitude in degrees.
def sun_latitude(time)
  solar_year_fraction = solar_year_fraction(time)
  # Use a sinusoidal approximation for the latitude of the sun.
  return 23.45 * Math.sin(2 * Math::PI * (solar_year_fraction))
end

# Computes longitude of the place on earth where the sun is in zenith at the
# given time.
# The time may be in any time zone.
# Returns the longitude in degrees.
def sun_longitude(time)
  # Compute the hours since the last noon at GMT
  time = time.utc
  hours = time.hour - 12 + time.min / 60.0 + time.sec / 3600.0
  return hours * -15
end

# Computes latitude and longitude of the place on earth where the sun is
# in zenith at the given time.
# The time may be in any time zone.
# Returns an array containing latitude and longitude in degrees.
def sun_location(time)
  return [sun_latitude(time), sun_longitude(time)]
end

# Checks if the sun is visible at the given location at the given time.
# Time may be in any time zone. location is [latitude, longitude] in degrees.
# Returns true if the sun is above the horizon, false otherwise.
def visible_at?(location, time)
  return visible?(sun_location(time), location)
end

# Computes what fraction of the maximum solar radiation is available at the
# given location and the given time for a solar module with the given tilt
# and bearing. The tilt is in degrees, 0 means flat on earth's surface, 90
# means vertical. The bearing is in degrees, 0 means north, 90 means east, ...
def solar_radiation_fraction(location, time, tilt, bearing)
  return 0.0 unless visible_at?(location, time)
  # Compute the sun's location at the given time.
  sun = sun_location(time)
  # Compute the orientation of the module
  module_orientation = orient(location, tilt, bearing)
  # Compute the cos of the angle between the sun and the module.
  cos = cos_of_angle_between(sun, module_orientation)
  # cos will be negative if the sun is behind the module.
  return 0.0 if cos < 0
  return cos
end

# Compute the cos of the angle between two earth locations.
def cos_of_angle_between(loc_a, loc_b)
  lat_a = loc_a[0] * Math::PI / 180
  lon_a = loc_a[1] * Math::PI / 180
  lat_b = loc_b[0] * Math::PI / 180
  lon_b = loc_b[1] * Math::PI / 180
  # compute dot product for unit vectors, which is the same as the cos
  return Math.cos(lat_a) * Math.cos(lat_b) * Math.cos(lon_a - lon_b) +
         Math.sin(lat_a) * Math.sin(lat_b)
end