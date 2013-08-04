require 'httparty'
require 'json'

puts "Generating list of random latlongs"

latlongs = []
(25...55).each do |lat|
  (60...130).each do |long|
    10.times do |lat_dec|
      10.times do |long_dec|
        lat_real = lat.to_f + (lat_dec.to_f / 10.0)
        long_real = long.to_f + (long_dec.to_f / 10.0)
        latlongs << [long_real * -1, lat_real]
      end
    end
  end
end

threads = []

segments = []
segment_count = 1000
segment_count.times do |n|
  start_index = n * (latlongs.size / segment_count)
  end_index = (n + 1) * (latlongs.size / segment_count) - 1
  segments << latlongs[start_index..end_index]
end

counties = {}
thread_count = 6
semaphore = Mutex.new
thread_count.times do |t_num|
  start_range = t_num * (latlongs.size / thread_count)
  end_range = (t_num + 1) * (latlongs.size / thread_count) - 1
  threads << Thread.new(4567 + t_num) do |port|
    while true
      body = nil
      semaphore.synchronize do
        puts segments.size
        body = segments.shift
      end
      break unless body
      response = HTTParty.get("http://localhost:#{port}/", body: body.to_json)
      response = JSON.load(response.body)
      semaphore.synchronize do
        response.each do |county, size|
          counties[county] ||= 0
          counties[county] += size
        end
      end
    end
  end
end
threads.each { |t| t.join }

counties = counties.to_a.sort_by { |k, size| size }
counties.each do |county, size|
  puts "% 25s %d" % [county, size]
end
