require 'sinatra'
require 'rgeo'
require 'rgeo-shapefile'
require 'json'

shapefile = 'shapefile/tl_2012_us_county.shp'
records = []
RGeo::Shapefile::Reader.open(shapefile) do |file|
  # Right now the records are just in an array
  # but we could build a trie or quad tree around the
  # enclosures of each shape to make searching for each one
  # even faster. This would essentially be an index on top
  # of the polygon records.
  file.each do |record|
    record.attributes["NAME"] = record.attributes["NAME"].force_encoding("ISO-8859-1")
    records << record
  end
end

get '/' do
  content_type :json
  if request.body
    points = JSON.load(request.body)
    points.map! { |point| RGeo::Geos.factory.point(point.first, point.last) }
    counties = {}
    points.each do |point|
      records.each do |record|
        if point.within? record.geometry
          name = "#{record.attributes["STATEFP"]} - #{record.attributes["NAME"]}"
          counties[name] ||= 0
          counties[name] += 1
          break
        end
      end
    end
    return counties.to_json
  end
end
