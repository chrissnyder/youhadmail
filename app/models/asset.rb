# The image being transcribed
class Asset
  include MongoMapper::Document
  include Randomizer
  
  # What is the native size of the image
  key :height, Integer, :required => true
  key :width, Integer, :required => true
  
  # What size should the image be displayed at
  key :display_width, Integer, :required => true
  
  key :uri, String, :required => true
  key :ext_ref, String
  key :order, Integer
  
  scope :in_collection, lambda { |asset_collection| where(:asset_collection_id => asset_collection.id)}

  timestamps!
  
  # belongs_to :template
  belongs_to :asset_collection
  
  
  # keeping this for if we need a random asset
  def self.random_for_transcription
    Asset.random(:limit => 1).first
  end
  
  
  def self.classification_limit
    5
  end

  # Don't want the image to be squashed
  def display_height
    (display_width.to_f / width.to_f) * height
  end
	
	def hocr_blocks
		(HocrDoc.find_by_uri uri).blocks
	end

	
end
