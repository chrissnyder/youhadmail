# a collection of AssetCollections!
class Archive
  include MongoMapper::Document

	key :title, String, :required => true
	key :description, String

	many :archive_constituents

end
