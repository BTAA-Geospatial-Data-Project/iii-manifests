require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'iiif-presentation'
end

require 'open-uri'
require 'iiif/presentation'


require 'bundler/inline'


# UMedia example item: Indian Atlas
url = "https://umedia.lib.umn.edu/item/p16022coll246:96.json"

data = JSON.parse(open(url).read)

# Example uses ngrok to tunnel local Rails app' public dir
# Need to set CORS headers appropriately
# See also: https://github.com/cyu/rack-cors
seed = {
  "@context" => "http://iiif.io/api/presentation/2/context.json",
  "@id" => 'https://raw.githubusercontent.com/BTAA-Geospatial-Data-Project/iiif-manifests/master/manifest_1ed5a86c-5e18-4fa1-a4d8-8c1cc1647f37.json',
  "@type" => "sc:Manifest",
  "label" => data["title"],
  "metadata" => [
    {
      "label" => "format",
      "value" => data["format"].join(', ')
    },
    {
      "label" => "subject",
      "value" => data["subject"].join(', ')
    },
  ],
  "seeAlso" => []
}

# Any options you add are added to the object
manifest = IIIF::Presentation::Manifest.new(seed)

manifest.sequences <<
  {
    "@type" => "sc:Sequence",
    "canvases" => []
  }

data['children'].each do |child|
  # Canvas for each page
  canvas = IIIF::Presentation::Canvas.new()

  canvas["@type"] = "sc:Canvas"
  canvas['@id'] = child['object']
  canvas["label"] = child['title']
  canvas["height"] = 1500
  canvas["width"] = 1500

  collection, id = child['id'].split(':')
  service_url = "https://cdm16022.contentdm.oclc.org/digital/iiif/#{collection}/#{id}/info.json"
  service_data = JSON.parse(open(service_url).read)

  image = {
    "@type": "oa:Annotation",
    "motivation": "sc:painting",
    "on": child['thumb_url'],
    "resource": {
      "@id": child['thumb_url'],
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
File.open("manifest_1ed5a86c-5e18-4fa1-a4d8-8c1cc1647f37.json","w") do |f|
  f.write(manifest.to_json(pretty: true))
end
