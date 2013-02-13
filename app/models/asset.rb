# The image being transcribed
class Asset
  include MongoMapper::Document
  include Randomizer
  
  # What is the native size of the image
  key :height, Integer, :required => true
  key :width, Integer, :required => true
  
  key :uri, String, :required => true
  key :ext_ref, String
  key :order, Integer
  
  scope :in_collection, lambda { |asset_collection| where(:asset_collection_id => asset_collection.id)}

  timestamps!
  
  belongs_to :asset_collection

	def signed_uri 
    self.class.sign_uri(uri).to_s
  end 

  def thumb_uri
    m = uri.match /\/([^\/]+\.jpg)$/
    filename = m[1]
    uri.sub /#{Regexp.escape(filename)}/, "thumbs/#{filename}"
    self.class.sign_uri(uri).to_s
  end 

  def self.sign_uri(uri)
    signed_uri = uri 
    m = uri.match /s3\.amazonaws\.com\/([^\/]+)/
		# PB: Let's not do signed uris. Just make them public 
    unless true or m.nil?
      bucket = m[1]

      s3_path = uri.match(/#{Regexp.escape(bucket)}\/(.+)/)[1]

      s3 = AWS::S3.new(
        :access_key_id => ENV['AWS_ACCESS_KEY'],
        :secret_access_key => ENV['AWS_SECRET_KEY']
      )   
      bucket = s3.buckets[bucket]
      object = bucket.objects[s3_path]
      signed_uri = object.url_for(:read, :force_path_style=>false)

    end 
    signed_uri

  end 
   
  def self.classification_limit
    5
  end

  # Don't want the image to be squashed
  def display_height
    (display_width.to_f / width.to_f) * height
  end
	
	def hocr_blocks
		(HocrDoc.find_by_asset self).blocks
	end

	def to_json(options = {})
		{
			:id => id, 
			:width => width, 
			:height => height, 
			:hocr_blocks => hocr_blocks, 
			:uri => signed_uri,
			:thumb_uri => thumb_uri
		}
	end
end
