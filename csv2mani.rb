require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'iiif-presentation'
end

require 'csv'
require 'open-uri'
require 'iiif/presentation'

# Open CSV File
csv_file = CSV.read("lincoln.csv", headers:true, header_converters: :symbol)

parent_record = {}

csv_file.each do |row|
  parent_record[:dc_title] = row[:dc_title]
  parent_record[:metadata] = []
  parent_record[:metadata] << {
    label: "Description",
    value: row[:dc_description]
  }

  parent_record[:metadata] << {
    label: "Creator",
    value: row[:dc_creator]
  }

#   parent_record[:metadata] << {
#     label: "Keywords",
#     value: row[:keywords]
#   }
  break
end

puts parent_record.inspect

seed = {
  "@context" => "http://iiif.io/api/presentation/2/context.json",
  "@id" => 'https://raw.githubusercontent.com/BTAA-Geospatial-Data-Project/iiif-manifests/master/manifest_414ade45-bef0-47ae-98a6-2b883c2642dd.json',
  "@type" => "sc:Manifest",
  "label" => parent_record[:dc_title],
  "metadata" => parent_record[:metadata],
  "seeAlso" => []
}

# Any options you add are added to the object
manifest = IIIF::Presentation::Manifest.new(seed)

puts manifest.inspect

manifest.sequences <<
  {
    "@type" => "sc:Sequence",
    "canvases" => []
  }

CSV.foreach("lincoln.csv", {headers:true, header_converters: :symbol}).with_index do |row, i|
  next if i == 0

  # Canvas for each page
  canvas = IIIF::Presentation::Canvas.new()

  canvas["@type"] = "sc:Canvas"
  canvas['@id'] = row[:iiif_service]
  canvas["label"] = row[:dc_title]
  canvas["height"] = 1500
  canvas["width"] = 1500

  service_url = row[:iiif_service]
  service_data = JSON.parse(open(service_url).read)

  image = {
    "@type": "oa:Annotation",
    "motivation": "sc:painting",
    "on": row[:iiif_service],
    "resource": {
      "@id": row[:iiif_service],
      "@type": "dctypes:Image",
      "format": "image/jpeg",
      "height": 1500,
      "width": 1500,
      "service": service_data
    }
  }

  canvas["images"] = []
  canvas["images"] << image

  manifest.sequences[0]["canvases"] << canvas
end

# Write manifest file
File.open("manifest_414ade45-bef0-47ae-98a6-2b883c2642dd.json","w") do |f|
  f.write(manifest.to_json(pretty: true))
end
