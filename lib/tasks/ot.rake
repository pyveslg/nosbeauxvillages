require 'open-uri'
require 'nokogiri'
require 'csv'
require "capybara"
require "selenium-webdriver"
require "geocoder"

namespace :ot do
  desc "Scrap French stations with  labels"

  task get: [:environment] do
  	def wait_for_ajax(capybara)
  	    Timeout.timeout(Capybara.default_max_wait_time) do
  	      loop until finished_all_ajax_requests?(capybara)
  	    end
  	end

  	def finished_all_ajax_requests?(capybara)
  	  capybara.evaluate_script('jQuery.active').zero?
  	end

		starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		puts "Collecting rough data..."

		filepath = 'data/cities/final_extracted_villages.csv'

  	def open(filepath)
			csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
			villages = []
			CSV.foreach(filepath, csv_options) do |row|
				villages << {
				  locality: row[0],
				  department: row[1],
				  region: row[2],
				  zipcode: row[3],
				  cog: row[4],
				  lat: row[5],
				  lng: row[6],
				  pop: row[7],
				  link: row[8],
				  label: row[9],
				  category: row[10],
				  site_name: row[11],
				}
			end
			villages
  	end


		villages = open(filepath).group_by{|village| village[:locality]}.select{|k, v| v.count == 1}.map(&:last).flatten
		villages_length = villages.length


		def search_google(capybara, el)
			new_url = "https://www.google.com/search?safe=active&q=#{el.gsub(/\s/, "+")}"
			capybara.visit(new_url)
			capybara.all("#rso .g")[0].find(".yuRUbf > a")["href"]
		end

		puts "fetching data..."

		capybara = Capybara::Session.new(:selenium_chrome_headless)
		all_villages = villages.map do |village|
			p village[:locality]
			url = "https://www.tourisme.fr/php/accueil_destination.php"
			# Start scraping
			capybara.visit(url)
			form_dest = capybara.find("#form-dest")
			form_dest.fill_in("champ_destination", with: village[:locality])

			best_options = capybara.all("#ui-id-1 li a")
			if best_options.count > 0 && best_options.count < 4
				best = best_options[0].text.strip
				form_dest.fill_in("champ_destination", with: best)
				capybara.find_button("bouton-submit").click
				h1 = capybara.find("h1").text.strip

				if h1 == "PAGE 404"
					h2 == /\/\d*\/(.*).htm.*/.match(capybara.current_path)[-1]
					website = search_google(capybara, h2)
				else
					if capybara.has_selector?("#btSite")
						capybara.find("#btSite").click
						# wait_for_ajax(capybara)
						website = capybara.find("#siteClair a")["href"]
					else
						website = search_google(capybara, h1)
					end
				end
			end
			h = {
  			locality: village[:locality],
  			department: village[:department],
  			region: village[:region],
  			zipcode: village[:zipcode],
  			cog: village[:cog],
  			lat: village[:lat],
  			lng: village[:lng],
  			pop: village[:pop],
  			link: village[:link],
  			label: village[:label],
  			category: village[:category],
  			site_name: village[:site_name],
  			ot_name: h1 ? h1 : "",
  			ot_www: website ? website : "",
  		}
  		if h1 || website
  			puts "✅ Village #{village[:locality]}'s OT is #{h1 ? h1 : "NO NAME 🙃"} (#{website ? website : "🔍"})"
  		end
  		puts "#{(villages.index(village).fdiv(villages_length)*100).round(1)} % completed"
  		h
		end

		csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
		filepath = 'data/cities/00_final_extracted_villages.csv'

		CSV.open(filepath, 'wb', csv_options) do |csv|
		  csv.to_io.write "\uFEFF"
		  csv << ["Locality", "Department", "Region", "Zipcode", "COG", "Latitude", "Longitude", "Population", "Link", "Label", "Category", "Site Name", "OT Name", "OT website"]
		  all_villages.each do |village|
		    csv << village.values
		  end
		end

		ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
		puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
  end
end
