require "test/unit"
require_relative "solar_radiation_fraction"
require "time"

class TestSolarDeclination < Test::Unit::TestCase
  # compares two floats between 0 and 1, allowing for wraparound (0 and 1 are
  # considered equal).
  def assert_wraparound_near(expected, actual, epsilon)
    # Both expected and actual have to be between 0 and 1.
    # Provide proper error messages if not.
    assert(expected >= 0, "expected value #{expected} is not between 0 and 1")
    assert(expected <= 1, "expected value #{expected} is not between 0 and 1")
    assert(actual >= 0, "actual value #{actual} is not between 0 and 1")
    assert(actual <= 1, "actual value #{actual} is not between 0 and 1")
    # If the difference is less than epsilon, we're done.
    return if (expected - actual).abs < epsilon
    # If the difference is greater than 1 - epsilon, we're done.
    return if (expected - actual).abs > 1 - epsilon
    # Otherwise, we have a problem.
    assert(false, "expected #{expected} to be near #{actual} (epsilon = " +
           "#{epsilon}), but the difference is #{actual - expected}")
  end
  def test_get_surrounding_elements
    assert_equal([0,1], get_surrounding_elements([0,1], 0))
    assert_equal([0,1], get_surrounding_elements([0,1], 0.25))
    assert_equal([0.5,1], get_surrounding_elements([0,0.5,1], 0.5))
    assert_throw(:not_found) { get_surrounding_elements([0,1], -1) }
    assert_throw(:not_found) { get_surrounding_elements([0,1], 1) }

    assert_equal([0,1,0.0], get_surrounding_elements([0,1], 0, 2))
    assert_equal([0,10,0.0], get_surrounding_elements([0,10,20,30], 05, 4))
    assert_equal([10,20,0.25], get_surrounding_elements([0,10,20,30], 15, 4))
    assert_equal([20,30,0.5], get_surrounding_elements([0,10,20,30], 25, 4))
    assert_equal([30,40,0.75], get_surrounding_elements([0,10,20,30,40], 35,4))
  end

  def compute_avarage_repetition_period(array)
    l = array.length - 1.0
    (1..l).map{|i| (array[i]-array[i-1]) / l}.sum
  end

  def test_compute_avarage_repetition_period
    assert_equal(1, compute_avarage_repetition_period([0,1]))
    assert_equal(0.5, compute_avarage_repetition_period([0,0.5,1]))
    assert_equal(0.25, compute_avarage_repetition_period([0,0.25,0.5,0.75,1]))
    assert_equal(0.25, compute_avarage_repetition_period([0,0.2,0.5,0.8,1]))
  end

  def test_solstice_and_equinox_rates
    # Compute the average period of solstice and equinox repetitions.
    # Verify that the average perios for each of these is 365 days, 5 hours,
    # 49 minutes.
    expected_period = (((365 * 24) + 5) * 60 + 49) * 60
    # expect an accuracy of 2 minutes
    epsilon = 2 * 60

    assert_in_delta(expected_period,
                    compute_avarage_repetition_period(March_Equinoxes),
                    epsilon)
    assert_in_delta(expected_period,
                    compute_avarage_repetition_period(June_Solstices),
                    epsilon)
    assert_in_delta(expected_period,
                    compute_avarage_repetition_period(September_Equinoxes),
                    epsilon)
    assert_in_delta(expected_period,
                    compute_avarage_repetition_period(December_Solstices),
                    epsilon)
  end

  def test_find_surrounding_seasonal_dates
    april_2023 = Time.parse("2023-04-01")
    assert_equal([March_Equinoxes[1], June_Solstices[1], 0],
                  find_surrounding_seasonal_dates(april_2023))
  end
  def test_solar_year_fraction
    # We can't expect more than 30 minutes accuracy, as the solar year
    # varies that much from the gravitational pull of the moon and other
    # planets.
    thirty_minutes_in_hours = 0.5
    year_in_hours = 365 * 24 + 5 + 49.0 / 60.0
    epsilon = thirty_minutes_in_hours / year_in_hours

    march_equinox_2023 = Time.parse("2023-03-20 22:24 CET")
    assert_wraparound_near(0, solar_year_fraction(march_equinox_2023), epsilon)

    june_solstice_2023 = Time.parse("2023-06-21 16:58 CEST")
    assert_in_delta(0.25, solar_year_fraction(june_solstice_2023), epsilon)

    september_equinox_2023 = Time.parse("2023-09-23 08:50 CEST")
    assert_in_delta(0.5, solar_year_fraction(september_equinox_2023), epsilon)

    december_solstice_2023 = Time.parse("2023-12-22 04:27 CET")
    assert_in_delta(0.75, solar_year_fraction(december_solstice_2023), epsilon)

    march_equinox_2030 = Time.parse("2030-03-20 15:00 CET")
    assert_in_delta(0, solar_year_fraction(march_equinox_2030), epsilon)
  end  

  def test_visible?
    # If sun is in zenith, it is visible
    assert(visible?([22,8],[22,8]))
    assert(visible?([0,0],[0,0]))
    
    # If sun is opposite zenith, it is not visible
    assert(! visible?([22,8],[-22,8+180]))
    assert(! visible?([0,0],[0,180]))

    # Sun is just visible at the horizon, but not just below
    assert(visible?([0,8],[0,8+90]))
    assert(! visible?([0,8],[0,8+90+1]))
    assert(! visible?([-1,8],[1,8+90]))
    assert(! visible?([1,8],[-1,8+90]))

    assert(visible?([0,8],[0,8-90]))
    assert(! visible?([0,8],[0,8-90-1]))

    # polar night
    assert(! visible?([-22,111],[69,111]))
    assert(! visible?([-22,111],[69,-98]))

    # polar day: midnight sun
    assert(visible?([22,199],[69,19]))
  end

  def test_orient
    # tilt of 0 degrees: orientation is equal to position regardless of bearing
    assert_equal([0,0], orient([0,0], 0, 0))
    assert_equal([0,0], orient([0,0], 0, 90))
    assert_equal([45,123], orient([45,123], 0, -7.5))

    # south orientation: elevation is lat - tilt
    assert_equal([0,0], orient([0,0], 0, 180))
    assert_equal([-10,0], orient([0,0], 10, 180))
    assert_equal([13,8], orient([53,8], 40, 180))

    # north orientation: elevation is lat + tilt
    assert_equal([-20,180], orient([-60,180], 40, 0))

    # east orientation
    assert_equal([0,90], orient([0,0], 90, 90))
    assert_equal([0,180], orient([0,90], 90, 90))
    assert_equal([0,98], orient([53,8], 90, 90))

    # other easily computable orientations
    assert_equal([-90,0], orient([0,0], 90, 180))
    assert_equal([90,0], orient([0,0], 90, 0))
    assert_equal([89,90], orient([0,0], 90, 1))
    assert_equal([-89,90], orient([0,0], 90, 179))
    assert_equal([-80,90], orient([0,0], 90, 170))
    
    # orient should normalize the result
    assert_equal([0,0], orient([0,0], 360, 360))

    # Check that our special cases for 0 and 180 degrees agree
    # with the general formula
    positions = [[53,8], [-23,179], [66,-70], [2.5,-99.3]]
    tilts = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90]
    bearings = [0, 180]
    deltas = [-0.01,0.01]
    positions.each do |lat,lon|
      tilts.each do |tilt|
        bearings.each do |bearing|
          special = orient([lat,lon], tilt, bearing)
          deltas.each do |delta|
            general = orient([lat,lon], tilt, bearing + delta)
            assert_in_delta(special[0], general[0], 0.3,
             "[lat=#{lat},lon=#{lon}],tilt=#{tilt},bearing=#{bearing+delta}" +
             (" special=%p, general=%p" % [special, general]))
            assert_in_delta(special[1], general[1], 0.3,
             "[lat=#{lat},lon=#{lon}],tilt=#{tilt},bearing=#{bearing+delta}" +
             (" special=%p, general=%p" % [special, general]))
          end
        end
      end
    end
  end

  def test_latlon2xyz
    assert_equal([1,0,0], latlon2xyz(0,0))
    assert_equal([0,1,0], latlon2xyz(0,90))
    assert_equal([0,0,1], latlon2xyz(90,0))
    assert_equal([0,0,-1], latlon2xyz(-90,77))
  end

  def test_xyz2latlon
    assert_equal([0,0], xyz2latlon(1,0,0))
    assert_equal([0,90], xyz2latlon(0,1,0))
    assert_equal([90,0], xyz2latlon(0,0,1))
    assert_equal([-90,0], xyz2latlon(0,0,-1))

    assert_equal([-42,-123], xyz2latlon(* latlon2xyz(-42,-123)))
    assert_equal([42,-123], xyz2latlon(* latlon2xyz(42,-123)))
    assert_equal([-42,123], xyz2latlon(* latlon2xyz(-42,123)))
  end

  def test_rotate()
    # rotate 0 degrees
    assert_equal([0,0], rotate([0,0], [12,34], 0))
    assert_equal([45,123], rotate([45,123], [77,-88], 0))

    # rotate 1 or 90 degrees
    assert_equal([0,-90], rotate([0,0], [90,0], 90))
    assert_equal([0,-1], rotate([0,0], [90,0], 1))
    
    assert_equal([0,0], rotate([0,90], [90,0], 90))
    
    assert_equal([-90,90], rotate([90,0], [0,0], 180))
    assert_equal([-89,90], rotate([90,0], [0,0], 179))
  end

  def test_sun_latitude
    # Sun position at the summer solstice should be at lat 23.45.
    summer = Time.parse("2023-06-21 14:58 UTC")
    assert_in_delta(23.45, sun_latitude(summer), 0.01)
    winter = Time.parse("2023-12-22 03:28 UTC")
    assert_in_delta(-23.45, sun_latitude(winter), 0.01)
  end

  def test_sun_longitude
    # Sun longitute at noon GMT should be at 0 degrees.
    assert_equal(0, sun_longitude(Time.parse("2023-06-21 12:00 UTC")))
    # The date does not matter:
    assert_equal(0, sun_longitude(Time.parse("2023-12-22 12:00 UTC")))
    assert_equal(0, sun_longitude(Time.parse("2023-01-01 12:00 UTC")))
    assert_equal(0, sun_longitude(Time.parse("2025-08-17 12:00 UTC")))

    # One hour before noon GMT, the sun should be at 15 degrees east.
    assert_equal(15, sun_longitude(Time.parse("2023-06-21 11:00 UTC")))
    assert_equal(15, sun_longitude(Time.parse("2023-12-22 11:00 UTC")))
    # half an hour after noon GMT, the sun should be at 7.5 degrees west.
    assert_equal(-7.5, sun_longitude(Time.parse("2023-06-21 12:30 UTC")))
    assert_equal(-7.5, sun_longitude(Time.parse("2023-12-22 12:30 UTC")))
  end
end
