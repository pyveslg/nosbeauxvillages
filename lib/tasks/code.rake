require 'open-uri'
require 'csv'
require 'i18n'
require "capybara"
require "selenium-webdriver"

namespace :code do

  task get: [:environment] do
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
				  link: row[7],
				  label: row[8],
				  category: row[9],
				  site_name: row[10],
				}
			end
			villages
  	end
  	extracted_villages = open(filepath)
  	st_villages = open(filepath).select{|village| !village[:cog] && /'+/.match?(village[:locality])}.each do |village|
  			extracted_villages.delete_at(extracted_villages.index(village))
  			village[:good_name] = village[:locality]
  			village[:locality] = village[:locality].gsub(/'/, "-")
  			if /Saint.?-(.*)/.match?(village[:locality])
  				village[:locality] = village[:locality].gsub(/Saint/, "ST")
  			end
  		end
  	clean_villages = extracted_villages - st_villages
  	p clean_villages.length
  	st_villages_length = st_villages.length

    unsuccessful_villages = []
		all_st_villages = st_villages.map do |village|
			url = "https://datanova.legroupe.laposte.fr/api/records/1.0/search/?dataset=laposte_hexasmal&q=#{I18n.transliterate(village[:locality])}&lang=fr&rows=1&geofilter.distance=#{village[:lat]},#{village[:lng]},10000"
			results = JSON.parse(
			  RestClient::Request.execute(
			    method: :get,
			    url: url,
			    headers: {
			    	'Accept': 'application/json',
			    	'cookie': 'TC_priv_Perso=false; tc_splitaudience2020=Population1; _cs_c=1; TCPID=1209213444410421757513; __gads=ID=d9b07d28f129815b:T=1600775085:S=ALNI_MarU6LaIUzIW1ESDqVmZhrTZ3ItrA; TC_PRIVACY=0@004@ALL@1@1600775107949@; TC_PRIVACY_CENTER=ALL; ry_ry-gr02p3l_realytics=eyJpZCI6InJ5X0I3Njc5RTAwLTdEREMtNDVCRC1CMTlELUYzNDRDMjQ0QzczNiIsImNpZCI6bnVsbCwiZXhwIjoxNjMyMzExMTExNTUwLCJjcyI6MX0%3D; cikneeto_uuid=id:6821da05-76ec-4bed-961b-c1315ae48a3c; _fbp=fb.1.1600775112313.1854171945; _tli=31422326546382443; _tlp=1968:11222441; _cs_id=5b51eacb-efda-aa7a-ecd2-6a2f7e545ceb.1600775084.3.1602238459.1602238459.1.1634939084057.Lax.0; _uetvid=31e9aaa00a1811eb984ce7ec7f58f473; _tlc=www.google.com%2F:1602238461:www.laposte.fr%2Foutils%2Fsuivre-vos-envois:laposte.fr; _tlv=3.1600775111.1600779078.1602238461.3.1.1; _MFB_=fHwxfHx8W118fDE2MDIyNDIwNjQ2NDd8fA==; _ga=GA1.3.600613990.1603546716; _gid=GA1.3.930630755.1603546716; csrftoken=iXOff6dobekUO9fIdPFyp4erpWmkZXUjWPyMCkO46Jd8IMTrZG1erIkoHMW6fWs0; sessionid=t08njjd2im4mqbwhjhrn9m5htq7m6ri6'
			    }
			  )
			)
			p url
			if results["nhits"] == 0
				unsuccessful_villages << village
				village[:locality] = village[:good_name]
				h = village
			else
				zipcode = results["records"][0]["fields"]["code_postal"]
				cog = results["records"][0]["fields"]["code_commune_insee"]
				h = {
				  locality: village[:good_name],
				  department: village[:department],
				  region: village[:region],
				  zipcode: zipcode,
				  cog: cog,
				  lat: village[:lat],
				  lng: village[:lng],
				  link: village[:link],
				  label: village[:label],
				  category: village[:category],
				  site_name: village[:site_name],
				}
			end
			puts "#{(st_villages.index(village).fdiv(st_villages_length)*100).round(1)} % completed"
			h
		end
		all_villages = clean_villages + all_st_villages
  	csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
  	filepath = 'data/cities/00_final_extracted_villages.csv'

  	CSV.open(filepath, 'wb', csv_options) do |csv|
  	  csv.to_io.write "\uFEFF"
  	  csv << ["Locality", "Department", "Region", "Zipcode", "COG", "Latitude", "Longitude", "Link", "Label", "Category", "Site Name"]
  	  all_villages.each do |village|
  	    csv << village.values
  	  end
  	end
  	puts "Still #{unsuccessful_villages.length} villages without insee code from this extract"
		ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		elapsed_time = ending - starting
		puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
	end

	task pop: [:environment] do
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
  	extracted_villages = open(filepath)
  	villages = extracted_villages.select{|village| village[:region] != "Corse" && !village[:pop]}
  	clean_villages = extracted_villages - villages
  	p extracted_villages.length
  	villages_length = villages.length
  	p villages_length
  	capybara = Capybara::Session.new(:selenium_chrome_headless)

  	puts "Starting fetching information..."
  	all_empty_villages = villages.map do |village|
  		village[:modified_cog] = "0#{village[:cog]}"
  		url = "https://www.data.gouv.fr/fr/territories/commune/#{village[:modified_cog]}/"
  		capybara.visit(url)
  		population = capybara.all('.tab-links p:last-child strong')
  		inhabitants = /\d.*/.match(population[0].text.strip)[0].gsub(/[[:space:]]/, "").to_i if population[0]
  		h = {
  			locality: village[:locality],
  			department: village[:department],
  			region: village[:region],
  			zipcode: village[:zipcode],
  			cog: village[:cog],
  			lat: village[:lat],
  			lng: village[:lng],
  			pop: inhabitants ? inhabitants : "",
  			link: village[:link],
  			label: village[:label],
  			category: village[:category],
  			site_name: village[:site_name],
  		}
  		puts "💁🏼‍♀️#{village[:locality]} has #{inhabitants} inhabitants"
  		puts "#{(villages.index(village).fdiv(villages_length)*100).round(1)} % completed"
  		h
  	end
  	all_villages = clean_villages + all_empty_villages
  	p all_villages.length

  	csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
  	filepath = 'data/cities/00_final_extracted_villages.csv'

  	CSV.open(filepath, 'wb', csv_options) do |csv|
  	  csv.to_io.write "\uFEFF"
  	  csv << ["Locality", "Department", "Region", "Zipcode", "COG", "Latitude", "Longitude", "Population", "Link", "Label", "Category", "Site Name"]
  	  all_villages.each do |village|
  	    csv << village.values
  	  end
  	end


  	ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  	elapsed_time = ending - starting
  	puts "⏱ Job done in #{(elapsed_time/60).floor} minutes and #{(elapsed_time%60).floor} seconds."
	end
end
