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
    	{
    		station_name: gare[:fields][:alias_libelle_noncontraint],
    		localty: gare[:fields][:commune_libellemin],
    		zipcode: gare[:fields][:adresse_cp],
    		department: gare[:fields][:departement_libellemin],
    		departement_numero: gare[:fields][:departement_numero],
    		latitude: gare[:geometry] ? gare[:geometry][:coordinates].last : "",
    		longitude: gare[:geometry] ? gare[:geometry][:coordinates].first : "",
    		scnf_region: gare[:fields][:gare_regionsncf_libelle],
    		cog: gare[:fields][:commune_code],
    	}
    end
  end

  def self.file
    Dir["#{File.dirname(__FILE__)}/../data/stations/*.json"]
  end
end
