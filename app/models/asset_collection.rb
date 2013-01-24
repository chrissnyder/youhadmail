class AssetCollection
  include MongoMapper::Document

  key :title, String, :required => true
  key :author, String, :required => false
  key :extern_ref, String
  key :template_id, ObjectId

  key :classification_count, Integer , :default => 0
  key :done, Boolean, :default => false 
  
  scope :active, :conditions => { :done => false }
  
  many :assets 
  many :transcriptions
	belongs_to :template
  
  def front_page
    self.assets.where.order(:order).first
  end
 
  def self.next_unseen_for_user(user)
		trans = user.transcriptions

		# FIXME: I don't know why I can't seem to just use #collect to gather asset_collection_ids here...
    # seen = trans.collect { |t| t.asset_collection_id }
		seen = []
		trans.each do |t|
			seen << t.asset_collection_id
		end

    coll = AssetCollection.active.where(:id.nin => seen).first
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


end
