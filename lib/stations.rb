require 'json'
require "deep_symbolize"

# Load all static yml data
class Stations
  def self.load
  	self.file.each do |file|
	    constant = File.basename(file, ".*")
	    const_set(constant.upcase, load_file(file))
  	end
  end

  private

  def self.load_file(file)
    gares = JSON.parse(File.read(file))
    all_gares = gares.map do |gare|
    	gare.extend DeepSymbolizable
    	gare.deep_symbolize { |key| key }
    end
    all_gares.map do |gare|
      fields = gare[:fields]
    	{
    		station_name: fields[:alias_libelle_noncontraint],
    		localty: fields[:commune_libellemin],
    		zipcode: fields[:adresse_cp],
    		department: fields[:departement_libellemin],
    		departement_numero: fields[:departement_numero],
    		latitude: gare[:geometry] ? gare[:geometry][:coordinates].last : "",
    		longitude: gare[:geometry] ? gare[:geometry][:coordinates].first : "",
    		scnf_region: fields[:gare_regionsncf_libelle],
        cog: "#{fields[:departement_numero]}#{fields[:commune_code]}",
    	}
    end
  end

  def self.file
    Dir["#{File.dirname(__FILE__)}/../data/stations/*.json"]
  end
end
