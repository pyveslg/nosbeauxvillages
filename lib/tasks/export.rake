require 'open-uri'
require 'csv'


namespace :export do
	desc "Export French villages"

	task all: [ :environment ] do
		villages = Village.all
		all_villages = villages.map do |village|
			labels = village.labels.map(&:name).compact
			links = village.village_labels.map(&:link).compact
			{
				id: village.id,
				localty: village.localty,
				department: village.department,
				region: village.region,
				zipcode: village.zipcode,
				cog: village.cog,
				latitude: village.latitude,
				longitude: village.longitude,
				population: village.population,
				number_of_labels: labels.count,
				grand_site: labels.include?("Grand Site de France"),
				grand_site_next: labels.include?("Grand Site de France (En cours)"),
				plus_beaux: labels.include?("Les Plus Beaux Villages de France"),
				detour: labels.include?("Les Plus Beaux Détours de France"),
				caractere: labels.include?("Petite Cité de Caractère"),
				station_classe: labels.include?("Station Classée"),
				links: links.empty? ? "" : links,
			}
		end

		csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
		filepath = 'data/cities/save_all.csv'

		CSV.open(filepath, 'wb', csv_options) do |csv|
		  csv.to_io.write "\uFEFF"
		  csv << ["Id", "Locality", "Department", "Region", "Zipcode", "Cog", "Latitude", "Longitude", "Population", "#Labels", "Grand Site", "Grand Site (En cours)", "PBVF", "Détours", "Caractere", "Station Classée", "Links"]
		  all_villages.compact.each do |village|
		    csv << village.values
		  end
		end
	end

	task ots: [ :environment ] do
		ots = Office.all
		all_ots = ots.map do |ot|
			{
				id: ot.id,
				name: ot.name,
				sanitized_name: ot.sanitized_name,
				department: ot.department,
				region: ot.region,
				latitude: ot.latitude,
				longitude: ot.longitude,
				ot1: ot.ot1,
				ot2: ot.ot2,
			}
		end

		csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
		filepath = 'data/ots/save_all_ots.csv'

		CSV.open(filepath, 'wb', csv_options) do |csv|
		  csv.to_io.write "\uFEFF"
		  csv << ["Id", "Name", "Sanitez Name", "Department", "Region", "Latitude", "Longitude", "Ot_1", "Ot_2"]
		  all_ots.compact.each do |ot|
		    csv << ot.values
		  end
		end
	end

	# task upload: [:environment] do
	# 	puts "Collecting rough data..."
	# 	filepath = "data/ots/ots.csv"
	# 	def open(filepath)
	# 		csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
	# 		ots = []
	# 		CSV.foreach(filepath, csv_options) do |row|
	# 			ots << {
	# 			  name: row[1],
	# 			  department: row[2],
	# 			  region: row[3],
	# 			  latitude: row[4].to_f,
	# 			  longitude: row[5].to_f,
	# 			  ot1: row[6],
	# 			}
	# 		end
	# 		ots
	# 	end


	# 	all_ots = open(filepath)
	# 	all_ots.each do |ot|
	# 		office = Office.create(ot)
	# 		puts "#{all_ots.count} ots updated in the database" if office.update(ot)
	# 	end
	# end
end
