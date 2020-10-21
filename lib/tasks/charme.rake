require 'static'
require 'open-uri'
require 'nokogiri'
require 'csv'
require "geocoder"

namespace :charme do
  desc "Scrap Villages de Charme"

  task urls: [:environment] do
    url = "http://www.villagesdefrance.fr/page_france.htm"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    all_departments = html_doc.search('map[name="FPMap1"] area').map do |element|
      "http://www.villagesdefrance.fr/#{element['href']}"
    end
    def clean_url(url)
    	uri = "http://www.villagesdefrance.fr/#{url}"
    	begin
    	  open(uri)
	  	rescue OpenURI::HTTPError
	  	  return "http://www.villagesdefrance.fr/dept/#{url}"
	  	else
	  	  return uri
	  	end
    end
    all_villages = all_departments.map do |dept|
    	html_file = open(dept).read
    	html_doc = Nokogiri::HTML(html_file)
    	regex = /\.\.\/(.*)/
    	all_dept_villages = html_doc.search('table:nth-of-type(2) tr:first-child > td:nth-child(2) map:nth-of-type(1) area').map do |element|
    		href = element['href']
    		sub_url = regex.match(href)[1] if regex.match(href)
    		url = sub_url ? sub_url : href
    		clean_url(url)
    	end
    	dept_villages = all_dept_villages.uniq
    	p dept_explicit_villages = {
    		dept: dept,
    		length: dept_villages.length,
    		villages: dept_villages
    	}
    	dept_villages
    end
    all_villages.flatten!
    all_villages.compact!
  end

  task get: [:environment] do
  	Static.load
  	URLS = Static::CHARME.group_by{|input| input[:dept]}.transform_values{|value| value.map{|v| v[:url]}}

  	def sanitize(text)
  		text.split(/\s+/).delete_if{|v| v == ":"}.join(' ')
  	end

  	all_villages = URLS.transform_values do |data|
  			data.map do |url|
	  			html_file = open(url).read
	  		  html_doc = Nokogiri::HTML(html_file)
	  		  village_name = sanitize(html_doc.search('table:first-of-type td:nth-of-type(2) font:first-child')[0].text.strip)
	  		  if /(villages\s)/.match?(village_name.downcase)
	  		  	sub_villages = html_doc.search('table td > font:first-of-type').map do |nom|
	  		  		sanitize(nom.text.strip)
	  		  	end
	  		  end
	  		  input = sub_villages ? sub_villages : village_name
  		  	p input
  		  end
  	end
  	all_villages = all_villages.transform_values{|value| value.flatten.compact.uniq}
  	csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
  	filepath    = 'data/cities/villages_de_charme.csv'

  	CSV.open(filepath, 'wb', csv_options) do |csv|
  	  csv.to_io.write "\uFEFF"
  	  csv << ['Village', 'Department']
  	  all_villages.each do |dept, villages|
  	  	villages.each{|village| csv << [village, dept]}
  	  end
  	end
  end


  task geocode: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "Collecting rough data..."
  	csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
  	filepath = 'data/cities/villages_de_charme.csv'
  	villages = []
  	CSV.foreach(filepath, csv_options) do |row|
  	  villages << {
  	    locality: /s\//.match?(row[0]) ? row[0].gsub('s/', "sur ") : row[0],
  	    department: row["Name"]
  	  }
  	end
  	not_success_villages = []
  	puts "Starting Geocoding villages"
  	villages_length = villages.length
  	all_villages = villages.map do |village|
  		puts "#{(villages.index(village).fdiv(villages_length)*100).round(1)} % completed"
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
  	      longitude: result.data["lon"]
  	    }
  	  end
  	  not_success_villages << village if !h
  	  h
  	end
  	puts "🎉 #{all_villages.length - not_success_villages.length} villages are now perfectly geocoded !"
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "You should manually geocode these ones (#{not_success_villages.length}:"
  	p not_success_villages

  	# // SUCCESSFULLY GEOCODED
  	csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
  	filepath = 'data/cities/villages_de_france.csv'

  	CSV.open(filepath, 'wb', csv_options) do |csv|
  	  csv.to_io.write "\uFEFF"
  	  csv << ["Locality", "Department", "Region", "Zipcode", "Latitude", "Longitude"]
  	  all_villages.compact.each do |village|
  	    csv << village.values
  	  end
  	end

  	# UNSUCCESSFULLY_GEOCODED
  	csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
  	filepath = 'data/cities/villages_de_france_to_be_reviewed.csv'

  	CSV.open(filepath, 'wb', csv_options) do |csv|
  	  csv.to_io.write "\uFEFF"
  	  csv << ["Locality", "Department"]
  	  not_success_villages.compact.each do |village|
  	    csv << village.values
  	  end
  	end

  	ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	elapsed_time = ending - starting
  	puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  end


  task geocode_reviewed: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "Collecting rough data..."
  	csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
  	filepath = 'data/cities/villages_de_france_reviewed.csv'
  	villages = []
  	CSV.foreach(filepath, csv_options) do |row|
  	  villages << {
  	    locality: row[0],
  	    department: row["Department"],
  	    reference: row["Reference"]
  	  }
  	end
  	not_success_villages = []
  	puts "Starting Geocoding villages"
  	villages_length = villages.length
  	all_villages = villages.map do |village|
  		puts "#{(villages.index(village).fdiv(villages_length)*100).round(1)} % completed"
  	  result = Geocoder.search("#{village[:reference]} #{village[:department] if village[:department] != "Gironde"} France").first
  	  if result
  	    address = result.data["address"]
  	    village_type = ["city", "town", "village", "hamlet", "suburb"]
  	    h = {
  	      locality: village[:locality],
  	      department: address["county"],
  	      region: address["state"],
  	      zipcode: address["postcode"],
  	      latitude: result.data["lat"],
  	      longitude: result.data["lon"]
  	    }
  	  end
  	  not_success_villages << village if !h
  	  h
  	end
  	puts "🎉 #{all_villages.length - not_success_villages.length} villages are now perfectly geocoded !"
  	puts "~~~~~~~~~~~~~~~~~~~~~~~~"
  	puts "You should manually geocode these ones (#{not_success_villages.length}:"
  	p not_success_villages

  	# // SUCCESSFULLY GEOCODED
  	csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
  	filepath = 'data/cities/villages_de_france_2.csv'

  	CSV.open(filepath, 'wb', csv_options) do |csv|
  	  csv.to_io.write "\uFEFF"
  	  csv << ["Locality", "Department", "Region", "Zipcode", "Latitude", "Longitude"]
  	  all_villages.compact.each do |village|
  	    csv << village.values
  	  end
  	end
  end
end
