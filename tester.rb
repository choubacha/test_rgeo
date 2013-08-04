require 'rgeo'
require 'rgeo/shapefile'

puts "Generating list of random latlongs"

latlongs = []
counties = {}
rnd = Random.new
fact = RGeo::Geos.factory
(35...45).each do |lat|
  (70...120).each do |long|
    10.times do |lat_dec|
      10.times do |long_dec|
        lat_real = lat.to_f + (lat_dec.to_f / 10.0)
        long_real = long.to_f + (long_dec.to_f / 10.0)
        latlongs << fact.point(long_real * -1, lat_real)
      end
    end
  end
end

require 'benchmark'

shapefile = 'shapefile/tl_2012_us_county.shp'
RGeo::Shapefile::Reader.open(shapefile) do |file|
  puts "File contains #{file.num_records} records."
  puts "Lat-Long contains #{latlongs.size} points."

  # Right now the records are just in an array
  # but we could build a trie or quad tree around the
  # enclosures of each shape to make searching for each one
  # even faster. This would essentially be an index on top
  # of the polygon records.
  records = []
  done = false
  Benchmark.bm(25) do |x|
    x.report("loading all shapes") do
      file.each { |record| records << record }
    end

    x.report("Processing shapes") do
      latlongs.each do |point|
        records.each do |record|
          counties[record.attributes["NAMELSAD"]] ||= []
          if point.within?(record.geometry)
            counties[record.attributes["NAMELSAD"]] << point
            break # found a county, all for this point
          end
        end
      end
    end
  end
end
counties = counties.to_a.sort_by { |k, points| points.size }
counties.each do |county, points|
  puts "% 25s %d" % [county, points.size]
end
