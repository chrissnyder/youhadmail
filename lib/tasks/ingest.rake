
namespace :ingest do 
	desc "Import new assets in S3, creating derivs and tesseract assets as necessary"

	task :delete_all => :environment do
		
		Asset.delete_all
		AssetCollection.delete_all
		Archive.delete_all

	end

	task :ingest, [:name, :start, :limit, :template]  => :environment do |t, args|
		args.with_defaults(:start => 0, :limit => 1,:template=>"You Had Mail Template")

		# puts "getting #{args.name}, from methods: #{self.class.methods}"

		template = Template.find_by_name(args[:template])
		puts "Processing #{args.name}"

		case args.name
		when 'tilden'
			data = archive_tilden
		when 'herschel'
			puts "No"	# Not doing this collection now
			exit
			data = archive_herschel
		end

		archive = Archive.find_or_create_by_title(data[:title])
		archive[:description] = data[:description]
		constituents = data[:constituents].map { |c| ArchiveConstituent.new(:first_name => c[:first_name], :last_name => c[:last_name], :role => c[:role]) }
		archive.archive_constituents = constituents
		archive.save!
		puts "Processing archive with #{data[:collections].size} asset colls"
		
		data[:collections].shift(args.start.to_i)

		processed = 0
		data[:collections].each do |coll|
			puts "Processing coll #{args.start.to_i + processed} with #{coll.size} images"

			# Grab the first uuid to id the assetcoll
			uuid = coll[0][:uri]
			uuid = uuid.match(/([^\/]+)\.jpg$/)
			next if uuid.nil? or uuid.size < 2
			uuid = uuid[1]

			collection = AssetCollection.find_or_create_by_uri("http://labs.nypl.org/#{uuid}")
			collection.template_id = template.id
			collection.archive_id = archive.id
			collection.save!

			order = 0
			coll.each do |asset|
				puts "  Processing asset: #{asset[:uri]}"

				parts = asset[:uri].match /youhadmail.nypl.org\/(([^\/]+\/)+)([^\/]+\.jpg)$/

				next if parts.nil? or parts.size < 2

				subdir = parts[1]
				filename = parts[3]

				s3 = s3_client
				bucket = s3.buckets['youhadmail.nypl.org']


				# if deriv exists, skip resize
				deriv_path = "#{subdir.sub(/-source/,'')}#{filename}"
				if bucket.objects[deriv_path].exists?
					puts "    Deriv exists in s3, skipping resizes"
					local_path = self.localize_s3_asset deriv_path
					i = Magick::ImageList.new(local_path).pop

				# .. Otherwise, derivs must be generated:
				else
					puts "    Deriv DNE in s3; resizing"
					
					local_file_path = self.localize_s3_asset("#{subdir}#{filename}")

					i = Magick::ImageList.new(local_file_path).pop

					if i.columns > 1000
						puts "      Resizing #{subdir}#{filename}"
						i.change_geometry!('1000x') do |cols, rows, img|
							img.resize!(cols, rows)
						end 
						i.write local_file_path
					end

					# Upload deriv
					subdir = subdir.sub /-source/, ''
					bucket.objects["#{subdir}#{filename}"].write(:file => local_file_path, :acl => :public_read)
					puts "      Wrote #{local_file_path} => #{subdir}#{filename}"


					# Generate thumb
					s3_thumb_path = "#{subdir}thumbs/#{filename}"
					i.change_geometry!('170x') do |cols, rows, img|
						img.resize!(cols, rows)
					end 
					i.write local_file_path
					# Upload thumb
					bucket.objects[s3_thumb_path].write(:file => local_file_path, :acl => :public_read)
				end

				# Update Asset record
				uri = asset[:uri].sub /-source/, ''
				asset = Asset.find_or_create_by_uri uri
				asset.width = i.columns
				asset.height = i.rows
				asset.order = order
				asset.asset_collection = collection
				asset.save

				order += 1
			end

			processed += 1
			if processed >= args.limit.to_i
				break
			end
		end

	end

	def self.localize_s3_asset(remote_path)
		ext = File.extname(remote_path)
		local_path = "#{Rails.root}/tmp/out#{ext}"

		s3 = s3_client
		bucket = s3.buckets['youhadmail.nypl.org']
		local_file = File.open(local_path,'wb') do |f|
			f.puts bucket.objects[remote_path].read
		end
		local_path
	end

	def archive_tilden
		s3_base_path = 'images/tilden-source'
		files = s3_list s3_base_path
		filenames = files.map { |f| f.key.split(/\//).pop }
		# puts "files: #{p filenames}"

		require 'csv'
		csv = CSV.read(self.localize_s3_asset("images/tilden-source/metadata.csv"))

		colls = []

		current_group_id = 0
		collection = nil
		csv.each do |line|
			group_id = line[4]
			if group_id != current_group_id
				colls << collection unless collection.nil? or collection.empty?
				# puts "added coll: #{p collection}"
				collection = []
				current_group_id = group_id
			end

			uuid = line[7]
			# puts "#{filenames.size} includes #{filenames.include? "#{uuid}.jpg"}"
			if filenames.include? "#{uuid}.jpg"
				uri = "https://s3.amazonaws.com/youhadmail.nypl.org/#{s3_base_path}/#{uuid}.jpg"
				collection << {:uri => uri}
			end
		end
		colls << collection unless collection.nil? or collection.empty?

		{
			:collections => colls,
			:title => 'Samuel J. Tilden',
			:description => "Samuel J. Tilden 1814-1886 served as Governor of New York, 1875-1876, and was the Democratic nominee for the Presidency in 1876. Tilden began his career as a corporate lawyer; he served as Corporate Counsel for the City of New York, as a member of the New York State Assembly, and as Chairman of the Democratic National Convention. Monies from his estate contributed to the founding of The New York Public Library. His papers document his political and legal career and are comprised primarily of correspondence, political and legal files, financial documents, writings, speeches, and personal papers dating from 1785 - 1929 bulk 1832 - 1886.",
			:constituents => [
				{:first_name => 'Samuel J.', :last_name => 'Tilden', :role => 'primary', :image_uri => 'http://upload.wikimedia.org/wikipedia/commons/1/18/STilden.JPG'}
			]
		}
	end

	def archive_herschel
=begin
		s3_base_path = 'images/herschel-source'
		files = s3_list s3_base_path
		puts "  Got #{files.size} source files"

		s3 = s3_client
		bucket = s3.buckets['youhadmail.nypl.org']

		ret = []
		files.each do |f| 
			# remote_filename = Pathname.new(f.key).basename.to_s
			# uri = "https://s3.amazonaws.com/youhadmail.nypl.org/#{f.key}"

			parts = f.key.match /(([^\/]+\/)+)([^\/]+\.pdf)$/
			next if parts.nil? or parts.size < 2
			subdir = parts[1]
			filename = parts[3]
			puts "  Processing source file: #{subdir}, #{filename}"

			local_file_path = "#{Rails.root}/tmp/out.pdf"
			local_file = File.open(local_file_path,'wb') do |f|
				f.puts bucket.objects["#{subdir}#{filename}"].read
			end

			images = Magick::ImageList.new(local_file_path)
			puts "Processing #{images.size} image letter"
			order = 0
			images.each do |i|
				s3_key = "#{subdir}/#{f}.#{order}.jpg"
				remote_uri = "https://s3.amazonaws.com/#{args[:bucket]}/#{s3_key}"
				puts "remote uri: #{remote_uri}"

				asset = Asset.find_or_create_by_uri remote_uri
				asset.width = i.columns
				asset.height = i.rows
				asset.order = order
				asset.asset_collection = collection 

				puts "  Saving db record for asset #{asset.order} (#{asset.width}x#{asset.height})"

				asset.save!

				s3_path = "#{args[:subdir]}/#{f}.#{order}.jpg"
				remote_uri = "https://s3.amazonaws.com/#{s3_path}"
				puts "remote uri: #{remote_uri}"
				s3_thumb_path = "#{args[:subdir]}/thumbs/#{f}.#{order}.jpg"
				# puts "thumb: #{s3_thumb_path}"

				local_file = "#{Rails.root}/tmp/out.jpg"
				i.write local_file
				bucket.objects[s3_path].write(:file => local_file)
				puts "upload #{local_file} to #{s3_path}"

				i.change_geometry!('170x') do |cols, rows, img|
					img.resize!(cols, rows)
				end 
				i.write local_file
				bucket.objects[s3_thumb_path].write(:file => local_file)
				puts "upload #{local_file} to #{s3_thumb_path}"

				order += 1
			end
			ret << {:uri => uri}

		end
		ret
=end
	end

	def s3_client
		s3 = AWS::S3.new(
			:access_key_id => ENV['AWS_ACCESS_KEY'],
			:secret_access_key => ENV['AWS_SECRET_KEY']
		)
	end

	def s3_list(path)
		s3 = s3_client

		bucket = s3.buckets['youhadmail.nypl.org']
		tree = bucket.as_tree(:prefix => path)

		tree.children.select(&:leaf?).collect(&:object)
	end

end # end namespace
