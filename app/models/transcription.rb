# A Transcription is a user-transcription of an Asset and is composed of many Annotations
class Transcription
  include MongoMapper::Document
  
  after_save :update_classification_count
  
  # key :page_data , Hash 
  
  key :collection_id, ObjectId

  timestamps!
  
  belongs_to :asset_collection
  belongs_to :user
  
  many :annotations
  
  
  def update_classification_count
    self.asset_collection.increment_classification_count
  end
  
  def add_annotations_from_json(new_annotations)
     unless new_annotations.blank?
      new_annotations.values.collect do |ann|
        # entity = Entity.find_by_name ann["entity_name"]
        entity = Entity.find ann["entity_id"]
        if entity
          self.annotations << Annotation.create(:data => ann[:data], :entity => entity, :bounds => ann[:bounds], :asset_id => ann[:asset_id])
        else
          puts "could not find entity type #{ann['entity_name']}"
        end
      end
    end
  end
end
