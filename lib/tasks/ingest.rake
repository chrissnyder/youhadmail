
namespace :ingest do 
	desc "Import new assets in S3, creating derivs and tesseract assets as necessary"
	task :prepare, [:start_index, :limit]  => :environment do |t, args|
		args.with_defaults(:start_index => 0, :limit => 1)

		TMP_PATH = Rails.root + '/tmp'

		require 'aws/s3'

		template = Template.find_by_name("Playbills Transcription Template")
		
		s3 = AWS::S3.new(
			:access_key_id => ENV['AWS_ACCESS_KEY'],
			:secret_access_key => ENV['AWS_SECRET_KEY']
		)
		bucket = s3.buckets['programs-cropped.nypl.org']
		tree = bucket.as_tree(:prefix => '10')
		files = tree.children.select(&:leaf?).collect(&:object)

		# date = DateTime.new(2012,2,3,4,5,6,'-4')
		# files.select! { |f| f.key.match(/\.tif$/) and f.last_modified > date }
		order = 0

		processed = 0
		single_page_count = 0
		collection = nil

		files.each_index do |i| 
			next if i < args.start_index.to_i

			remote_file = files[i]

			puts "\nProcessing #{remote_file.key}"

			local_file_path = "#{TMP_PATH}/s3_programs-cropped_#{remote_file.key.gsub('/','.')}"

			unless FileTest.exists? local_file_path
				local_file = File.open(local_file_path,'wb') do |f|
					f.puts remote_file.read
					puts "  Downloaded #{remote_file.key} to #{local_file_path}"
				end
			end

			remote_filename = Pathname.new(remote_file.key).basename.to_s
			origin_uri = "https://s3.amazonaws.com/programs-cropped.nypl.org/#{remote_file.key}"

			# Skip if already saved
			# next if Asset.find_by_uri origin_uri
			# puts "Asset with uri #{origin_uri} not found; creating.."

			s3_hocr_path = 'tesseract/' + remote_file.key.sub(/\.jpg$/,'.html')
			local_hocr_path = "#{TMP_PATH}/s3_programs-cropped_hocr_" + s3_hocr_path.gsub('/','.')

			# Skip if any ocr assets missing in S3
			unless bucket.objects[s3_hocr_path].exists?
				
				unless FileTest.exists?(local_hocr_path)
					puts "  Creating hocr: #{local_hocr_path}"

					system "tesseract", local_file_path, "#{TMP_PATH}/out", 'batch.nochop', 'hocr'

					FileUtils.cp "#{TMP_PATH}/out.html", local_hocr_path
				end

				puts "  Uploading hocr: #{local_hocr_path} => #{s3_hocr_path}"
				bucket.objects[s3_hocr_path].write(:file => local_hocr_path)
			end

			if remote_file.key.match /\/\d+\.jpg/
				single_page_count += 1
			else
				single_page_count = 0
			end

			# if this is a first page, reset order var
			if single_page_count > 1
				order = 0
				single_page_count = 0

				unless collection.nil?
					processed += 1

					if processed >= args.limit.to_i
						puts "Processed #{processed} playbills; exiting"
						exit
					end
				end
			end

			if order == 0
				puts "  Encountered start of AssetCollection (http://labs.nypl.org/playbills/#{Digest::MD5.hexdigest(origin_uri)}"
				collection = AssetCollection.find_or_create_by_uri("http://labs.nypl.org/playbills/#{Digest::MD5.hexdigest(origin_uri)}")
				collection.template_id = template.id
				collection.save!
			end
			asset = Asset.find_or_create_by_uri origin_uri

			image = Magick::ImageList.new(local_file_path).shift
			asset.width = image.columns
			asset.height = image.rows
			asset.order = order
			asset.asset_collection = collection 

			puts "  Saving db record for asset #{asset.order} (#{asset.width}x#{asset.height})"

			asset.save!

			s3_thumb_path = 'thumbs/' + remote_file.key
			unless bucket.objects[s3_thumb_path].exists?
				local_thumb_path = "#{TMP_PATH}/s3_programs-cropped_" + s3_thumb_path.gsub('/','.')

				puts "  Uploading thumb: #{local_thumb_path} => #{s3_thumb_path}"

				image.change_geometry!('170x') do |cols, rows, img|
					img.resize!(cols, rows)
				end 
				image.write local_thumb_path
				bucket.objects[s3_thumb_path].write(:file => local_thumb_path)
				bucket.objects[s3_thumb_path].acl = :public_read
			end

		
			order += 1


		end
	end # end task

	task :delete_all => :environment do
		
		Asset.delete_all
		AssetCollection.delete_all

	end
end # end namespace
