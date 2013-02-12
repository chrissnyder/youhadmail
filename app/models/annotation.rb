# A collection of Annotations makes up a Transcription
class Annotation
  include MongoMapper::Document
  
	key :asset_id, ObjectId
	key :asset_collection_id, ObjectId
  key :bounds, Hash # this is x-rel,  y-rel, with-rel, height-rel measure (0..1)
  key :data, Hash # A hash looking something like :field_key => "Some value"
  
  after_create :denormalize_to_asset
  
  timestamps!
  
  # belongs_to :transcription
  belongs_to :entity
  belongs_to :user
  belongs_to :asset

	def as_json(options={})
		{	:id => id,
			:user => {:name => 'User.' + user.id, :id => user.id},
			:asset_id => asset_id,
			:bounds => bounds,
			:data => data,
			:entity_id => entity.id,
		}
	end
  
  def denormalize_to_asset
    asset.add_to_set annotations: { key: entity.name, value: data }
  end
end
