class Village < ApplicationRecord
	has_many :village_labels
	has_many :labels, through: :village_labels


	geocoded_by :address

	scope :with_label, -> { joins(:labels) }
	scope :with_specific_label, -> (label) { joins(:labels).where("name = ? ",label) }
	scope :with_link, -> { joins(:village_labels).where("link IS NOT ?", nil) }

	def address
		"#{localty} #{department} #{region} France"
	end

end
