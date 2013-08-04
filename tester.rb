require 'rgeo'
require 'rgeo/shapefile'

puts "Generating list of random latlongs"

latlongs = []
rnd = Random.new
fact = RGeo::Geos.factory
100_000.times do |n|
  puts "#{n} generated..." if n % 10000 == 0
  lat = rnd.rand(10).to_f + 35.0 + rnd.rand
  long = rnd.rand(40).to_f + 70 + rnd.rand
  long *= -1
  latlongs << fact.point(long, lat)
end

require 'benchmark'

shapefile = '/Users/kbacha/Downloads/tl_2012_us_county/tl_2012_us_county.shp'
RGeo::Shapefile::Reader.open(shapefile) do |file|
  puts "File contains #{file.num_records} records."
  segments = [[], [], [], []]
  done = false
  Benchmark.bm(25) do |x|
    file.num_records.times do |n|
      record = nil
      x.report("loading shape #{n + 1}") { record = file.next }
      if record
        x.report(record.attributes["NAMELSAD"]) do
          latlongs.each { |point| point.within?(record.geometry) }
        end
      else
        done = true
      end
    end
  end

  # file.each do |record|
  #   segments[record.index % 4] << record
  #   puts "#{record.index} - #{record.attributes["NAMELSAD"]}"
  # end

  # 4.times do |segment|
  #   Process.fork do
  #     segments[segment].each do |record|
  #       name = record.attributes["NAMELSAD"]
  #       latlongs.each do |point|
  #         puts " Found: #{point} in #{name}" if point.within?(record.geometry)
  #       end
  #     end
  #   end
  # end
  # file.rewind
  record = file.next
  puts "First record geometry was: #{record.geometry.as_text}"
end
