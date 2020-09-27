require 'open-uri'
require 'nokogiri'
require 'csv'
require "capybara"
require "selenium-webdriver"
require "geocoder"

namespace :villages do
  desc "Scrap French villages with labels"
  task detours: [ :environment ] do

    url = "https://www.plusbeauxdetours.com/plan-du-site/"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)

    regex = /^Détour par (.*) (dans|en)(les|l’|la|le|\s)+(.*)$/i
    elements = html_doc.search('li.page-item-74.page_item_has_children .page_item a')

    all_villages = elements.map do |element|
      text = element.text.strip
      {
        village_name: regex.match?(text) ? regex.match(text)[1] : "",
        village_dpt: regex.match?(text) ? regex.match(text)[-1] : "",
        village_link: element.attribute('href').value,
        label: "Les Plus Beaux Détours de France"
      }
    end

    csv_options = { col_sep: ',', force_quotes: true, quote_char: '"', encoding: "UTF-8" }
    filepath    = 'plus_beaux_detours_de_france.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ['Name', 'Department', 'Link', 'Label']
      all_villages.each do |village|
        csv << village.values
      end
    end
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
    filepath    = 'petites_cites_de_caractere.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ['Name', 'Department', 'Link', 'Label']
      all_villages.each do |village|
        csv << village.values
      end
    end
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
    filepath    = 'grands_site_de_france.csv'

    CSV.open(filepath, 'wb', csv_options) do |csv|
      csv.to_io.write "\uFEFF"
      csv << ['Name', 'Label']
      all_villages.compact.each do |village|
        csv << village.values
      end
    end
  end

end


