require 'open-uri'
require 'json'
require "deep_symbolize"
require 'turf_ruby'
require 'string/similarity'

namespace :compare do

	task ots: [:environment] do
		starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		puts "Collecting rough data..."
		filepath = "data/main_ots_for_villages.json"
		village_ots = JSON.parse(File.read(filepath)).values[0].map do |ot|
    	ot.extend DeepSymbolizable
    	ot.deep_symbolize { |key| key }
    end
    village_ots_length = village_ots.count

		village_ots.map do |village_ot|
			offices = Office.select{|ot| village_ot[:ots].include?(ot.ot1)}
			village = Village.find(village_ot[:village_id])
			point = [village.longitude, village.latitude]
			distances = offices.map{|office| [office.id, Turf.distance(point, [office.longitude, office.latitude], units: "kilometers").floor]}
			closer_ots = distances.select{|array| array[1] < 3}
			if closer_ots.empty?
				distances = distances.select{|array| array[1] < 15}
				word_diffs = distances.map do |array|
					office = Office.find(array[0]).name.upcase
					ot = Office.find(array[0]).ot1.gsub(/^OT /, "Office de tourisme ").upcase
					[array[0], String::Similarity.levenshtein(office, ot)]
				end
				if !word_diffs.blank?
					ot = Office.find(word_diffs.sort{|o1, o2| o2[1] <=> o1[1]}[0][0])
				end
			else
				ot = Office.find(closer_ots[0][0])
			end
			if ot
				info = {
					office: ot.name.strip,
					coordinates: [ot.longitude, ot.latitude],
					epci: ot.ot1.strip,
					distance: Turf.distance(point, [ot.longitude, ot.latitude], units: "kilometers").round(1)
				}
				village.ot = info
				puts "✅ #{village.localty} has now #{info[:office]} as ot" if village.save
			end
			puts "#{(village_ots.index(village_ot).fdiv(village_ots_length)*100).round(1)} % completed"
		end
		ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
		puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
	end

	task empty_ots: [:environment] do
		starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		puts "Collecting rough data..."
		villages = Village.select{|village| village.ot.blank?}
		villages_length = villages.count
		villages.map do |village|
			point = [village.longitude, village.latitude]
			nearest_office = Office.all.map{|office| [office.id, Turf.distance(point, [office.longitude, office.latitude], units: "kilometers")]}.sort{|a1, a2| a1[1] <=> a2[1]}[0]
			ot = Office.find(nearest_office[0])
			info = {
				office: ot.name.strip,
				coordinates: [ot.longitude, ot.latitude],
				epci: ot.ot1.strip,
				distance: Turf.distance(point, [ot.longitude, ot.latitude], units: "kilometers").round(1)
			}
			village.ot = info
			puts "✅ #{village.localty} has now #{info[:office]} as ot" if village.save
		end
		ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
		puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  end

end
