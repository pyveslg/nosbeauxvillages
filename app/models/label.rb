class Label < ApplicationRecord
	validates :name, uniqueness: true
	has_many :village_labels
	has_many :villages, through: :village_labels
end
