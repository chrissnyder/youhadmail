class AssetCollection
  include MongoMapper::Document

  key :uri, String
  key :template_id, ObjectId

  key :classification_count, Integer , :default => 0
  key :done, Boolean, :default => false 
  
  scope :active, :conditions => { :done => false }
  
  many :assets, :sort => 'uri'
  # many :transcriptions
  many :annotations
	belongs_to :template
  
  def front_page
    self.assets.where.order(:order).first
  end
 
  def self.next_unseen_for_user(user)
		seen_collection_ids = user.annotations.map { |ann| ann.asset_collection_id }
		logger.debug "seen ids: #{seen_collection_ids}"

		# FIXME: I don't know why I can't seem to just use #collect to gather asset_collection_ids here...
    # seen = trans.collect { |t| t.asset_collection_id }
=begin
		seen = []
		trans.each do |t|
			seen << t.asset_collection_id
		end
=end

    coll = AssetCollection.active.where(:id.nin => seen_collection_ids).first
		# logger.debug "selected unseen coll: #{p coll.id} because not in user (#{user.id})'s trans: #{seen}"
		coll
  end 

  def remaining_active
    self.assets.where(:done=>false).count 
  end
  
  def active?
    self.remaining_active != 0 
  end 

  
  def increment_classification_count
    self.classification_count = self.classification_count+1
    if self.classification_count > 5
      self.done=true
    end
    self.save 
  end

=begin
	def assets_sorted
		assets.sort_by! { |asset| asset.order }
	end
=end

	def to_json(options = {})
		{
			:uri => uri,
			:template_id => template_id,
			:assets => assets.map {|a| a.to_json(options) }
		}
	end

end
