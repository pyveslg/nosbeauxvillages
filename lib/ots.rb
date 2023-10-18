require 'json'
require "deep_symbolize"

# Load all static yml data
class Ots
  def self.load
  	self.file.each do |file|
	    constant = File.basename(file, ".*")
	    const_set(constant.upcase, load_file(file))
  	end
  end

  private

  def self.load_file(file)
    ots = JSON.parse(File.read(file)).map do |ot|
    	ot.extend DeepSymbolizable
    	ot.deep_symbolize { |key| key }
    end
    all_ots = ots[0][1].partition.with_index { |_, i| i.even? }[1]
    all_ots.map do |ot|
    	{
    		name: ot[:properties][:name],
    		region: ot[:properties][:region],
    		poly: ot[:geometry][:coordinates]
    	}
    end
  end

  def self.file
    Dir["#{File.dirname(__FILE__)}/../data/ots/*.json"]
  end
end
