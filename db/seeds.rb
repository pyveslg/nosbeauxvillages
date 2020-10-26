# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

require 'open-uri'
require 'csv'

Village.destroy_all

puts "Collecting rough data..."

filepath = 'data/cities/final_extracted_villages.csv'

def open(filepath)
	csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
	villages = []
	CSV.foreach(filepath, csv_options) do |row|
		villages << {
		  localty: row[0],
		  department: row[1],
		  region: row[2],
		  zipcode: row[3],
		  cog: row[4],
		  latitude: row[5],
		  longitude: row[6],
		  population: row[7],
		  place: row[11],
		}
	end
	villages
end

def sanitize(village, code)
	if village[code.to_sym].to_s.length < 5
		village[code.to_sym] = "0#{village[code.to_sym]}"
	else
		village[code.to_sym]
	end
end


all_villages = open(filepath)
all_villages.each do |village|
	village[:place] = village[:localty] if village[:place].to_s.blank?
	village[:cog] = sanitize(village, "cog")
	village[:zipcode] = sanitize(village, "zipcode")
	village[:latitude] = village[:latitude].to_f
	village[:longitude] = village[:longitude].to_f
	Village.create(village)
end

puts "#{Village.all.count} villages created in the database"
