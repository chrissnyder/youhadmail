# A collection of Annotations makes up a Transcription
class Annotation
  include MongoMapper::Document
  
	key :asset_id, ObjectId
  key :bounds, Hash # this is x-rel,  y-rel, with-rel, height-rel measure (0..1)
  key :data, Hash # A hash looking something like :field_key => "Some value"
  
  timestamps!
  
  belongs_to :transcription
  belongs_to :entity
end
