task :ensure_indexes => :environment do	

	Annotation.ensure_index :asset_id
	Annotation.ensure_index :asset_collection_id

	Asset.ensure_index :asset_collection_id
	Asset.ensure_index :annotations

	AssetCollection.ensure_index :template_id
	AssetCollection.ensure_index :archive_id

	Entity.ensure_index  :template_id

end