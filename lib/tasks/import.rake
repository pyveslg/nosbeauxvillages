require 'open-uri'
require 'csv'

namespace :import do
	desc "Import French villages with labels"
	task grandsite: [ :environment ] do
		filepath = "data/cities/grands_site_de_france.csv"
		results = open(filepath)
		unsuccessful_villages = []
		all_villages = results.map do |result|
			villages = Village.where(localty: result[:localty])
			if villages.count > 1
				villages = villages.select{|village| village.place == result[:place]}
			end
			unsuccessful_villages << result if !villages[0]
			villages[0]
		end
		p unsuccessful_villages
		create_labels(results)
		all_villages.each_with_index do |village, index|
			label = Label.find_by(name: results[index][:label])
			if VillageLabel.where("label_id = ? AND village_id = ?", label, village).empty?
				if VillageLabel.create(label: label, village: village)
					puts "#{village.localty} is now labelled with #{label.name}"
				end
				village.place = results[index][:place]
				if village.save
					puts "#{village.localty} has now a place named after #{village.place}"
				end
			end
		end

		puts "👋 Have a closer look at the following villages :"
		p unsuccessful_villages
	end


	task plusbeaux: [:environment] do
		filepath = "data/cities/plus_beaux_villages_de_france.csv"
		results = open(filepath)

		all_villages = results.map do |result|
			villages = Village.where("localty = ? AND department = ?", result[:localty], result[:department])
			villages[0]
		end
		create_labels(results)
		all_villages.each_with_index do |village, index|
			label = Label.find_by(name: results[index][:label])
			if VillageLabel.where("label_id = ? AND village_id = ?", label, village).empty?
				if VillageLabel.create(label: label, village: village, link: results[index][:link])
					puts "#{village.localty} is now labelled with #{label.name}"
				end
			end
		end
		puts "✅ #{all_villages.length} villages are now labelled with Les Plus Beaux Villages de France"
	end


	task detour: [:environment] do
		filepath = "data/cities/plus_beaux_detours_de_france.csv"
		results = open(filepath)
		all_villages = results.map do |result|
			villages = Village.where("localty = ? AND department = ?", result[:localty], result[:department])
			villages[0]
		end
		create_labels(results)
		all_villages.each_with_index do |village, index|
			label = Label.find_by(name: results[index][:label])
			if VillageLabel.where("label_id = ? AND village_id = ?", label, village).empty?
				if VillageLabel.create(label: label, village: village, link: results[index][:link])
					puts "#{village.localty} is now labelled with #{label.name}"
				end
			end
		end
		puts "✅ #{all_villages.length} villages are now labelled with Les Plus Beaux Détours de France"
	end

	task caractere: [:environment] do
		filepath = "data/cities/petites_cites_de_caractere.csv"
		results = open(filepath)
		all_villages = results.map do |result|
			villages = Village.where("localty = ? AND department = ?", result[:localty], result[:department])
			villages[0]
		end
		create_labels(results)
		all_villages.each_with_index do |village, index|
			label = Label.find_by(name: results[index][:label])
			if VillageLabel.where("label_id = ? AND village_id = ?", label, village).empty?
				if VillageLabel.create(label: label, village: village, link: results[index][:link])
					puts "#{village.localty} is now labelled with #{label.name}"
				end
			end
		end
		puts "✅ #{all_villages.length} villages are now labelled with Petite Cité de Caractère"
	end

	task stations_classees: [:environment] do
		filepath = "data/cities/stations_classees.csv"

		results = open(filepath)
		results = results.map do |result|
			label = result[:label].split("[")[1].split("]")[0].split(",").map{|v| v.gsub("'", "")}.map{|v| v.strip}
			{
				localty: result[:localty],
				department: result[:department],
				label: label.include?("Station classée") ? "Station Classée" : ""
			}
		end
		results = results.select{|result| !result[:label].empty?}


		all_villages = results.map do |result|
			villages = Village.where("localty = ? AND department = ?", result[:localty], result[:department])
			villages[0]
		end
		create_labels(results)
		all_villages.each_with_index do |village, index|
			if village
				label = Label.find_by(name: results[index][:label])
				if VillageLabel.where("label_id = ? AND village_id = ?", label, village).empty?
					if VillageLabel.create(label: label, village: village, link: results[index][:link])
						puts "#{village.localty} is now labelled with #{label.name}"
					end
				end
			end
		end
		puts "✅ #{all_villages.length} villages are now labelled with Station Classée"
	end

	task test: [:environment] do
		filepath = "data/cities/stations_classees.csv"
		results = open(filepath)

		unsuccessful_villages = []
		all_villages = results.map do |result|
			villages = Village.where("localty = ? AND department = ?", result[:localty], result[:department])
			unsuccessful_villages << result[:localty] if villages.count > 1
			unsuccessful_villages << result[:localty] if !villages[0]
			villages[0]
		end
		p results.length

		p unsuccessful_villages
		p unsuccessful_villages.length
	end


	def open(filepath)
		csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
		villages = []
		CSV.foreach(filepath, csv_options) do |row|
			villages << {
			  localty: row[0],
			  department: row[1],
			  label: row[6],
			}
		end
		villages
	end

	def create_labels(results)
		labels = results.map{|result| result[:label]}.uniq
		labels.each do |label|
			Label.create(name: label) if !Label.find_by(name: label)
			puts "✅ #{label} was created in database"
		end
	end
end
