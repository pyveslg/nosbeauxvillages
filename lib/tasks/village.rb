require 'open-uri'
require 'nokogiri'

namespace :village do
  desc "Scrap French villages with labels"
  task plusbeaux: [ :environment ] do

    url = "https://www.plusbeauxdetours.com/plan-du-site/"
    html_file = open(url).read
    html_doc = Nokogiri::HTML(html_file)

    regex = /^Détour par (.*) (dans|en)(les|l'|la|le|\s)+(.*)$/i


    all_villages = html_doc.search('.page-item-74.page_item_has_children .page-item a').map do |element|
      text = element.text.strip
      {
        village_name: regex.match?(text) ? regex.match(text)[1] : "",
        village_dpt: regex.match?(text) ? regex.match(text)[-1] : "",
        village_link: element.attribute('href').value
        label: "Les Plus Beaux Détours de France"
      }
    end
    puts all_village
  end
end
