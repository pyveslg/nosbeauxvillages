require 'ots'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'turf_ruby'

namespace :ots do
  desc "Attribution d'un office de tourisme à chacun des villages"

  task get: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "Collecting rough data..."

  	ots = Ots::OTS
  	ots_length = ots.count
  	puts "Nous avons trouvé #{ots.length} offices majeurs de tourisme !"

  	villages = Village.all
  	villages_length = villages.count

  	villages = Offices::OFFICES
  	villages_length = villages.count

  	unsuccessful_villages = []
  	processed_villages = villages.map do |village|
  		point = Turf.point(village[:coordinates])
	  	# point = Turf.point([village.longitude, village.latitude])
	  	ots_polygon = ots.map do |ot|
	  		polies = ot[:poly].map{|o| Turf.polygon(o)}
	  		{ "#{ots.index(ot)}": {
	  				name: ot[:name],
	  				count: polies.count,
	  				polies: polies.map{|poly| Turf.boolean_point_in_polygon(point, poly)}.select{|p| p == true}.uniq.first
	  			}
	  		}
	  	end
	  	corresponding_ots = ots_polygon.select{|ot| ot.values[0][:polies] == true }.map do |value|
	  		ots[value.keys[0].to_s.to_i][:name]
	  	end
	  	number_of_ots = corresponding_ots.compact.count
	  	h = {
	  		name: village[:name],
	  		coordinates: village[:coordinates],
	  		ots: corresponding_ots.compact,
	  		ots_length: corresponding_ots.compact.count,
	  	}
	  	# h = {
	  	# 	village_id: village.id,
	  	# 	localty: village.localty,
	  	# 	ots: corresponding_ots.compact,
	  	# 	ots_length: corresponding_ots.compact.count,
	  	# }
	  	if number_of_ots == 0
	  		hamlet = "#{village[:name]}"
	  		# hamlet = "#{village.id} - #{village.localty} - #{village.department}"
	  		unsuccessful_villages << hamlet
	  		puts "😱 Oh no ! Nothing found for #{hamlet}"
	  	else
	  		puts "✅ #{village[:name]} depends on #{number_of_ots} ots (#{corresponding_ots.compact.join(', ')})!"
	  		# puts "✅ #{village.localty} depends on #{number_of_ots} ots (#{corresponding_ots.compact.join(', ')})!"
	  	end

	  	puts "#{(villages.index(village).fdiv(villages_length)*100).round(1)} % completed"
	  	h
  	end

  	ots = { villages: processed_villages }
  	filepath    = 'data/main_ots_for_ots.json'
  	# filepath    = 'data/ots/main_ots_for_villages.json'
  	File.open(filepath, 'wb') do |file|
  	  file.write(JSON.generate(ots))
  	end

  	ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "You shoul have a closed look at the following #{unsuccessful_villages.count } villages :"
  	p unsuccessful_villages
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  end

  task update_ot: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "Collecting rough data..."
  	filepath = "data/main_ots_for_ots.json"
  	ots = JSON.parse(File.read(filepath)).values[0]
  	ots_length = ots.length
  	all_ots = ots.each{|ot|
  		office = Office.find_by(name: ot["name"])
  		if !office
  			puts "↳ Preparing data for #{ot["name"]}..."
  			offices = ot["ots_length"] == 0 ? [ot["name"]] : ot["ots"]
  			tourism = Geocoder.search(ot["coordinates"].reverse).first
	  		h = {
	  			name: ot["name"],
	  			sanitized_name: tourism.cache_hit ? tourism.data["address"]["tourism"] : nil,
	  			department: tourism.cache_hit ? tourism.data["address"]["county"] : nil,
	  			region: tourism.cache_hit ? tourism.data["address"]["state"] : nil,
	  			latitude: ot["coordinates"][1],
	  			longitude: ot["coordinates"][0],
	  		}
	  		offices.each_with_index do |office, index|
	  			h["ot#{index + 1}".to_sym] = office
	  		end
	  		new_office = Office.create(h)
  			if new_office
  				puts "✅ #{new_office.name} was successfully created"
  			end
  		end
  		puts "#{(ots.index(ot).fdiv(ots_length)*100).round(1)} % completed"
  		# h
  	}
  	ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."

  	# csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
  	# filepath    = 'data/ots.csv'

  	# CSV.open(filepath, 'wb', csv_options) do |csv|
  	#   csv.to_io.write "\uFEFF"
  	#   csv << ['Name', 'Sanitized Name', 'Department', 'Region', 'Coordinates', "Ot_1", "Ot_2"]
  	#   all_ots.compact.each do |ot|
  	#     csv << ot.values
  	#   end
  	# end

  end

  task ot: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "Collecting rough data..."
  	ots = Offices::OFFICES
  	ots_length = ots.count
  	puts "Nous avons trouvé #{ots.length} offices de tourisme !"

  	villages = Village.all
  	villages_length = villages.count

  	# villages.map do |village|
  	village = villages[0]
  		point = [village.longitude, village.latitude]
  		distances = ots.map{|ot| [ots.index(ot), ot[:name], Turf.distance(point, ot[:coordinates], units: "kilometers")]}.sort{|d1, d2| d1[2] <=> d2[2]}
  		p distances.select{|d| d[2] < 20}
  		p village
  	# end
  end


  task test: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "Collecting rough data..."

  	ots = Ots::OTS
  	p ots.count
  	village = Village.find_by(localty: "Saint-Victor-sur-Loire")
  	p [village.longitude, village.latitude]
  	point = Turf.point([village.longitude, village.latitude])

  	ots_polygon = ots.map do |ot|
  		polies = ot[:poly].map{|o| Turf.polygon(o)}
  		{ "#{ots.index(ot)}": {
  				name: ot[:name],
  				count: polies.count,
  				polies: polies.map{|poly| Turf.boolean_point_in_polygon(point, poly)}.select{|p| p == true}.uniq.first
  			}
  		}
  	end

  	p ots_polygon
  end
end
