require 'open-uri'
require 'nokogiri'
require 'csv'
require "capybara"
require "selenium-webdriver"
require "geocoder"

namespace :geocode do
  desc "Scrap French stations with  labels"

  task villages: [:environment] do
		starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		puts "Collecting rough data..."

		filepath = 'data/cities/all_selected_villages.csv'

  	def open(filepath)
			csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
			villages = []
			CSV.foreach(filepath, csv_options) do |row|
				villages << {
				  locality: row[0],
				  department: row[1],
				  region: row[2],
				  zipcode: row[3],
				  lat: row[4],
				  lng: row[5],
				  link: row[6],
				  label: row[7],
				  category: row[8],
				  site_name: row[9],
				}
			end
			villages
  	end

		villages_to_geocode = open(filepath).select{|village| village if !village[:lat]}
		villages_to_geocode_length = villages_to_geocode.length

		not_success_villages = []
		puts "Starting Geocoding villages"
		all_villages = villages_to_geocode.map do |village|
		  result = Geocoder.search("#{village[:locality]} #{village[:department]} France").first
		  if result
		    address = result.data["address"]
		    village_type = ["city", "town", "village", "hamlet", "suburb"]
		    h = {
		      locality: village_type.map{|v| address[v]}.compact.first,
		      department: address["county"],
		      region: address["state"],
		      zipcode: address["postcode"],
		      latitude: result.data["lat"],
		      longitude: result.data["lon"],
		      link: village[:link],
				  label: village[:label],
				  category: village[:category],
				  site_name: village[:site_name],
		    }
		  end
		  not_success_villages << village if !h
			puts "#{(villages_to_geocode.index(village).fdiv(villages_to_geocode_length)*100).round(1)} % completed"
		  h
		end
		puts "🎉 #{all_villages.length - not_success_villages.length} villages are now perfectly geocoded !"
		puts "~~~~~~~~~~~~~~~~~~~~~~~~"
		puts "You should manually geocode these ones (#{not_success_villages.length}:"
		p not_success_villages

		# // SUCCESSFULLY GEOCODED
		csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
		filepath = 'data/cities/new_geocoded_villages.csv'

		CSV.open(filepath, 'wb', csv_options) do |csv|
		  csv.to_io.write "\uFEFF"
		  csv << ["Locality", "Department", "Region", "Zipcode", "Latitude", "Longitude", "Link", "Label", "Category", "Site Name"]
		  all_villages.compact.each do |village|
		    csv << village.values
		  end
		end

		# UNSUCCESSFULLY_GEOCODED
		csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
		filepath = 'data/cities/review_ungeocoded_villages.csv'

		CSV.open(filepath, 'wb', csv_options) do |csv|
		  csv.to_io.write "\uFEFF"
		  csv << ["Locality", "Department", "Region", "Zipcode", "Latitude", "Longitude", "Link", "Label", "Category", "Site Name"]
		  not_success_villages.compact.each do |village|
		    csv << village.values
		  end
		end

		ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
		puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  end
end
