require 'open-uri'
require 'nokogiri'
require 'csv'
require "capybara"
require "selenium-webdriver"
require "geocoder"

namespace :stations do
  desc "Scrap French stations with  labels"

  task get: [:environment] do
    url = "https://www.communes-touristiques.net/anmscct/membres/"
    capybara = Capybara::Session.new(:selenium_chrome_headless)
    # Start scraping
    capybara.visit(url)
    regex = /(.*)\((\d*)\)/i
    count = 0
    total = capybara.all("#listeMembres li").count
    all_villages = capybara.all("#listeMembres li").map do |li|
      count += 1
      if li[:class] != "multiple" && li.text.match?(regex)
        capybara.execute_script("document.getElementById('#{li[:id]}').click()")
        lugar = capybara.find("#membres > div:first-child > h1")
        locality = lugar.text.match(regex)[1].strip
        department = lugar.text.match(regex)[-1].strip
        category = capybara.find("#membres > div:first-child > span").text.strip
        ot = capybara.find("#membres > div:first-child > .web")[:href] if capybara.has_selector?("#membres > div:first-child > .web")
        labels = capybara.find("#membres > div:first-child > .labels").text.strip

        h = {
          locality: locality,
          department: department,
          category: category,
          ot: ot,
          labels: labels.split("|").map{|word| word.strip}
        }

        capybara.execute_script("document.querySelector('.fermer').click()")
        sleep(0.5)
        p h
        h
      end
    end

    csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
    filepath    = 'data/cities/stations_de_france.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ["Locality", "Department", "Category", "Tourism Office", "Labels"]
      all_villages.compact.each do |village|
        csv << village.values
      end
    end
  end

  task geocode: [:environment] do
    csv_options = { col_sep: ';', quote_char: '"', encoding: "UTF-8", headers: :first_row }
    filepath = 'data/cities/stations_de_france.csv'
    villages = []
    CSV.foreach(filepath, csv_options) do |row|
      villages << {
        locality: row[0],
        department: row["Department"],
        category: row["Category"],
        ot: row["Tourism Office"],
        labels: row["Labels"]
      }
    end

    all_villages = villages.map do |village|
      result = Geocoder.search("#{village[:locality]} #{village[:department]} France").first
      if result
        result = result.data["address"]
        village_type = ["city", "town", "village", "hamlet", "suburb"]
        h = {
          locality: village_type.map{|v| result[v]}.compact.first,
          department: result["county"],
          region: result["state"],
          zipcode: result["postcode"],
          category: village[:category],
          ot: village[:ot],
          labels: village[:labels]
        }
      end
      p h
    end

    csv_options = { col_sep: ';', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
    filepath = 'data/cities/stations_de_france.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ["Locality", "Department", "Region", "Zipcode", "Category", "Tourism Office", "Labels"]
      all_villages.compact.each do |village|
        csv << village.values
      end
    end
  end
end
