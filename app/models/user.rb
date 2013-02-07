class User
	include MongoMapper::Document

	# key :id, Integer, :required => true
	key :email, String, :required => true

	timestamps!

	# many :transcriptions
	many :annotations

  def add_annotations_from_json(new_annotations, collection_id)
     unless new_annotations.blank?
      new_annotations.values.collect do |ann|
        # entity = Entity.find_by_name ann["entity_name"]
        entity = Entity.find ann["entity_id"]
        if entity
          self.annotations << Annotation.create(:data => ann[:data], :entity => entity, :bounds => ann[:bounds], :asset_id => ann[:asset_id], :asset_collection_id => collection_id)
        else
          puts "could not find entity type #{ann['entity_name']}"
        end
      end
    end
  end
end
