require 'stations'
require 'open-uri'
require 'nokogiri'

namespace :gares do
  desc "Liste de toutes les gares de voyageurs en France"

  task create: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "Collecting rough data..."

  	Stations.load
  	gares = Stations::GARES
  	gares_length = gares.count
  	puts "Nous avons trouvé #{gares.length} gares de voyageurs !"

  	puts "Starting completing data via geocoder"

  	gares.each do |gare|
  		if !Gare.find_by(place: gare[:station_name])
	  		extract_region = Geocoder.search("[#{gare[:latitude]},#{gare[:longitude]}]").first
	  		if extract_region
	  			region = extract_region.data["address"]["state"]
	  		else
	  			region = Geocoder.search("#{gare[:zipcode]} France").first.data["address"]["state"]
	  		end
	  		h = {
	  			place: gare[:station_name],
	  			localty: gare[:localty],
	  			department: gare[:department],
	  			region: region,
	  			zipcode: gare[:zipcode],
	  			cog: "#{gare[:departement_numero]}#{gare[:cog]}",
	  			latitude: gare[:latitude],
	  			longitude: gare[:longitude],
	  			region_sncf: gare[:scnf_region],
	  		}
	  		new_gare = Gare.create(h)
	  		puts "✅ Gare #{new_gare.place} in #{new_gare.localty} (#{new_gare.region}) has been created!" if new_gare
	  	end
  		puts "#{(gares.index(gare).fdiv(gares_length)*100).round(1)} % completed"
  	end

  	ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
		puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "🚀 #{Gare.count} gares created !"
  end
end
