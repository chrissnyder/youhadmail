class User
	include MongoMapper::Document

	# key :id, Integer, :required => true
	key :email, String, :required => true

	timestamps!

	many :transcriptions

end
