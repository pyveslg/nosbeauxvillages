require 'open-uri'
require 'nokogiri'
require 'csv'
require "geocoder"

namespace :plus_beaux do
  desc "Scrap French Plus Beaux Villages de France"

  task get: [:environment] do
    url = "https://www.les-plus-beaux-villages-de-france.org/fr/nos-villages/"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    all_villages = html_doc.search('div.result').map do |element|
      {
        name: element.element_children.search('.name')[0].text.strip,
        dpt: element.element_children.search('.locality')[0].text.strip,
        lat: element.attribute('data-latitude').value,
        lng: element.attribute('data-longitude').value,
        img_url: element.attribute('data-map-thumbnail').value,
        link: "https://www.les-plus-beaux-villages-de-france.org#{element.attribute('data-uri').value}",
        label: "Les Plus Beaux Villages de France"
      }
    end

    all_villages = all_villages.map do |village|
      result = Geocoder.search("#{village[:name]} #{village[:dpt]} France").first
      if result
        result = result.data["address"]
        village_type = ["city", "town", "village", "hamlet", "suburb"]
        h = {
          locality: village_type.map{|v| result[v]}.compact.first,
          department: result["county"],
          region: result["state"],
          zipcode: result["postcode"],
          lat: village[:lat],
          lng: village[:lng],
          img_url: village[:img_url],
          ot: village[:link],
          label: village[:label]
        }
      else
        h = {
          locality: village[:name],
          department: village[:dpt],
          region: "",
          zipcode: "",
          lat: village[:lat],
          lng: village[:lng],
          img_url: village[:img_url],
          ot: village[:link],
          label: village[:label]
        }
      end
      p h
    end


    csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
    filepath    = 'data/cities/plus_beaux_villages_de_france.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ['Name', 'Department', 'Region', 'Zipcode', 'Latitude', 'Longitude', 'Cover_url', 'Link', 'Label']
      all_villages.compact.each do |village|
        csv << village.values
      end
    end
  end

  task open: [:environment] do
    csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
    filepath = 'data/cities/plus_beaux_villages_de_france.csv'
    villages = []
    CSV.foreach(filepath, csv_options) do |row|
      villages << {
        locality: row[0],
        department: row[1],
        region: row[2],
        zipcode: row[3],
        lat: row[4],
        lng: row[5],
        cover_url: row[6],
        ot: row[7],
        label: row[8]
      }
    end
    p villages
    # TO DO SAVE TO VILLAGE
  end
end
