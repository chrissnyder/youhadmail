# a collection of AssetCollections!
class ArchiveConstituent
  include MongoMapper::EmbeddedDocument

	key :last_name, String, :required => true
	key :first_name, String, :required => true
	key :image_uri, String
	key :relationship, String

	embedded_in :archive
end
