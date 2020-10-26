require 'open-uri'
require 'nokogiri'
require 'csv'
require "capybara"
require "selenium-webdriver"
require "geocoder"

namespace :villages do
  desc "Scrap French villages with labels"
  task detours: [ :environment ] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	puts "connecting to website..."
    url = "https://www.plusbeauxdetours.com/plan-du-site/"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)

    regex = /^Détour par (.*) (dans|en)(les|l’|la|le|\s)+(.*)$/i
    elements = html_doc.search('li.page-item-74.page_item_has_children .page_item a')

    puts "gathering information..."
    all_villages = elements.map do |element|
      text = element.text.strip
      {
        village_name: regex.match?(text) ? regex.match(text)[1] : "",
        village_dpt: regex.match?(text) ? regex.match(text)[-1] : "",
        village_link: element.attribute('href').value,
        label: "Les Plus Beaux Détours de France"
      }
    end
    puts "🚀 #{all_villages.length} villages found"
    puts "saving and exporting information..."
    csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
    filepath    = 'data/cities/plus_beaux_detours_de_france.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ['Name', 'Department', 'Link', 'Label']
      all_villages.each do |village|
        csv << village.values
      end
    end

    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed_time = ending - starting
    puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  end

  task caractere: [:environment] do
    all_villages = []

    20.times do |index|
      if index == 0
        url = "http://petitescitesdecaractere.com/fr/resultats-de-recherche/%2A"
      else
        url = "http://petitescitesdecaractere.com/fr/resultats-de-recherche/%2A?page=#{index}"
      end
      html_file = open(url).read
      html_doc = Nokogiri::HTML(html_file)
      html_doc.search('.search-result a').each do |element|
        text = element.text.strip
        all_villages << {
          village_name: text,
          village_dpt: "",
          village_link: "http://petitescitesdecaractere.com#{element.attribute('href').value}",
          label: "Petite Cité de Caractère"
        }
      end
    end

    csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
    filepath    = 'data/cities/petites_cites_de_caractere.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ['Name', 'Department', 'Link', 'Label']
      all_villages.each do |village|
        csv << village.values
      end
    end
  end

  task test: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		puts "Collecting rough data..."

		filepath = 'data/cities/petites_cites_de_caractere.csv'

  	def open(filepath)
			csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
			villages = []
			CSV.foreach(filepath, csv_options) do |row|
				villages << {
				  locality: row[0],
				  department: row[1],
				  link: row[2],
				  label: row[3]
				}
			end
			villages
  	end

  	puts "start fetching information..."
  	villages = open(filepath)
  	villages_length = villages.length

    capybara = Capybara::Session.new(:selenium_chrome_headless)
   	all_villages = villages.map do |village|
	    # Start scraping
	    capybara.visit(village[:link])
	    contact = capybara.all("#block-fieldblock-taxonomy-term-communes-default-field-blocks .field-items .field-item.even")[-1]
	    infos = contact.all("strong")
	    ot_link = contact.all("a").map{|link| link['href']}.select{|link| /www/.match?(link)}[0]
	    ot_name = infos[0].text.strip if infos[0]
	    mairie = infos[1].text.strip if infos[1]
	    regex = /\((.*)\)/
	    departement = regex.match(mairie)[-1] if mairie && regex.match?(mairie)
	    h = {
	    	locality: village[:locality],
	    	departement: departement,
	    	link: village[:link],
	    	label: village[:label],
	    	ot_name: ot_name,
	    	ot_link: ot_link
	    }
	    puts "#{(villages.index(village).fdiv(villages_length)*100).round(1)} % completed"
	    h
	  end
	  csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
	  filepath    = 'data/cities/petites_cites_de_caractere_with_dpt.csv'

	  CSV.open(filepath, 'wb', csv_options) do |csv|
	    csv.to_io.write "\uFEFF"
	    csv << ['Locality', 'Department', 'Link', 'Label', 'OT', 'OT_Web']
	    all_villages.each do |village|
	      csv << village.values
	    end
	  end

	  ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
		puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."

  end


  task grandsite: [:environment] do
    url = "https://www.grandsitedefrance.com/membres"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)
    all_villages = html_doc.search('.gmapfp_liste li span').map do |element|
      logo = element.search('img')[0].attribute('src').value
      if !logo.match?(/(orange-dot)/)
        {
          site_name: element.text.strip,
          label: logo.match?(/(site-membre2)/) ? "Grand Site de France (En cours)" : "Grand Site de France"
        }
      end
    end

    csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
    filepath    = 'data/cities/grands_site_de_france.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ['Name', 'Label']
      all_villages.compact.each do |village|
        csv << village.values
      end
    end
  end

  task geocode: [:environment] do
  	starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		puts "Collecting rough data..."

		filepath = 'data/cities/petites_cites_de_caractere_with_dpt.csv'

  	def open(filepath)
			csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
			villages = []
			CSV.foreach(filepath, csv_options) do |row|
				villages << {
				  locality: row[0],
				  department: row[1],
				  link: row[2],
				  label: row[3]
				}
			end
			villages
  	end

  	villages = open(filepath)
  	villages_length = villages.length

  	not_success_villages = []
		puts "Starting Geocoding villages"
  	all_villages = villages.map do |village|
  	  result = Geocoder.search("#{village[:locality]} #{village[:department] if village[:department]} France").first
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
  	    }
  	  end
  	  not_success_villages << village if !h
  		puts "#{(villages.index(village).fdiv(villages_length)*100).round(1)} % completed"
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
  	  csv << ["Locality", "Department", "Region", "Zipcode", "Latitude", "Longitude", "Link", "Label"]
  	  all_villages.compact.each do |village|
  	    csv << village.values
  	  end
  	end

  	ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	elapsed_time = ending - starting
  	puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  end

end


