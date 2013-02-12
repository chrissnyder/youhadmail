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
  key :annotations, Array
  
  scope :in_collection, lambda { |asset_collection| where(:asset_collection_id => asset_collection.id)}

  timestamps!
  
  # belongs_to :template
  belongs_to :asset_collection
  
  def self.annotations(filter = { })
    pipeline = where
    
    filter.try :each_pair do |key, value|
      pipeline = pipeline.match annotation_filter(key, value)
    end
    
    pipeline.project(annotations: true)
      .unwind('$annotations')
      .project(annotation: '$annotations')
      .group(_id: '$annotation.key', asset_id: { :$first => '$_id' }, values: {
        :$addToSet => '$annotation.value'
      })
  end
  
	def signed_uri 
		# https://s3.amazonaws.com/programs-cropped.nypl.org/10/00030.jpg

		signed_uri = uri
		cropped_progs_base_uri = 'https://s3.amazonaws.com/programs-cropped.nypl.org'
		if uri.match /#{Regexp.escape(cropped_progs_base_uri)}/

			s3_path = uri.match(/#{Regexp.escape(cropped_progs_base_uri)}\/(.+)/)[1]

			s3 = AWS::S3.new(
				:access_key_id => ENV['AWS_ACCESS_KEY'],
				:secret_access_key => ENV['AWS_SECRET_KEY']
			)
			bucket = s3.buckets['programs-cropped.nypl.org']
			object = bucket.objects[s3_path]
			signed_uri = object.url_for(:read, :force_path_style=>false)
			logger.debug "Getting s3 path for #{s3_path}: #{object.key} => #{signed_uri}"

			# signed_url = bucket_gen.get(URI.unescape(URI.parse(URI.escape(path)).path[1..-1]), 24.hour)
		end
		signed_uri
	end

	def thumb_uri
		uri.sub(/\/programs-cropped.nypl.org/, '/programs-cropped.nypl.org/thumbs')
	end
  
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
		(HocrDoc.find_by_asset self).blocks
	end

	def to_json(options = {})
		{
			:id => id, 
			:width => width, 
			:height => height, 
			:hocr_blocks =>[], # hocr_blocks, 
			:uri => signed_uri.to_s,
			:thumb_uri => thumb_uri,
			:fladeedle => 'doo'
		}
	end
  
  protected
  def self.annotation_filter(key, value)
    if value.is_a?(Hash)
      { 'annotations.key' => key }.tap do |filter|
        value.each_pair{ |k, v| filter["annotations.value.#{ k }"] = v }
      end
    elsif value
      { 'annotations.key' => key, 'annotations.value' => value }
    else
      { 'annotations.key' => key }
    end
  end
end
