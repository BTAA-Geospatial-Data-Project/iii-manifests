require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'json'
  gem 'iiif-presentation'
end

require 'open-uri'
require 'iiif/presentation'

# UMedia example item: Standard atlas of Kittson county
url = "https://umedia.lib.umn.edu/item/p16022coll231:2045.json"
data = JSON.parse(open(url).read)

# Example uses ngrok to tunnel local Rails app' public dir
# Need to set CORS headers appropriately
# See also: https://github.com/cyu/rack-cors
seed = {
  "@context" => "http://iiif.io/api/presentation/2/context.json",
  "@id" => 'http://7560ef37.ngrok.io/iiif_manifest.json',
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
File.open("manifest.json","w") do |f|
  f.write(manifest.to_json(pretty: true))
end
