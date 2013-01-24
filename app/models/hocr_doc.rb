
include Magick

class HocrDoc

	def self.find_by_uri(uri)
		return self.new :uri => uri
	end

	def initialize(params)
		@uri = params[:uri]
		if @uri[0].chr == '/'
			@uri = 'http://localhost:3001' + @uri
		end

		@asset_key = @uri.dup
		@asset_key.sub! /\.[a-z]{3,4}$/, ''
		@asset_key.sub! /^(\/|http:\/\/)/, ''
		@asset_key.gsub! /\//, '-'
		@asset_key.gsub! /[^a-zA-Z0-9-]/, ''

		local_path = source_image_path
		image = ImageList.new(local_path).shift
		@source_width = image.columns
		@source_height = image.rows

	end

	def blocks
		hocr_path = ocr_asset_path 'hocr'

		require 'rexml/document'
		content = File.read(hocr_path)

		blocks = []
		doc = REXML::Document.new content
		doc.root.elements.each("//div[@class='ocr_carea']") do |area|
		
			block = {
				:coords => parse_bbox(area.attribute('title').value[5..-1].split(' ')),
			}
			normalize! block[:coords], @source_width, @source_height
			block[:pars] = []

			area.each_element_with_attribute('class','ocr_par') do |par|
				lines = []
				par.each_element_with_attribute('class','ocr_line') do |line|
					l = {
						:coords => parse_bbox(line.attribute('title').value[5..-1].split(' ')),
					}
					normalize! l[:coords], @source_width, @source_height
					lines << l
				end
				block[:pars] << lines
			end

			blocks << block
		end

		if hocr_path.match(/tiff/)
			ratio = source_ratio
			
			blocks.each do |b|
				tmp = b[:coords][:ul][0]
				b[:coords] = scale_coords_down b[:coords], ratio
				b[:pars].each do |p|
					p.each do |l|
						l[:coords] = scale_coords_down l[:coords], ratio
						l[:words].each do |w|
							w[:coords] = scale_coords_down w[:coords], ratio
						end
					end
				end
			end
		end

		blocks
	end

	def normalize! (coords, orig_w, orig_h)
		coords[:ul][0] /= orig_w.to_f
		coords[:ul][1] /= orig_h.to_f
		coords[:w] /= orig_w.to_f
		coords[:h] /= orig_h.to_f
		# Logger.new('log/development.log').debug "normalized: #{coords.inspect}"
		coords
	end

	def source_image_path
		path = "tmp/#{@asset_key}.jpg"

		unless FileTest.exists?(path)
			require 'open-uri'

			Logger.new('log/development.log').debug "opening uri: #{@uri}"

			open(@uri) do |rf|
				Logger.new('log/development.log').debug "writing to #{path}"
				File.open(path, 'wb') do |wf|
					wf.puts rf.read
				end
			end
		end

		path
	end

	def ocr_asset_path type
		
		path = "tmp/#{@asset_key}.#{type}"

		unless false && FileTest.exists?(path)

			s3 = AWS::S3.new(
				:access_key_id => Transcribe::Application.config.aws_access_key, 
				:secret_access_key => Transcribe::Application.config.aws_secret_key
			)
			box_dir = 'training/box'
			m = @uri.match /\/(\d+\/\d+(\.\d+)?)\.jpg$/

			remote_path = "tesseract/#{m[1]}.#{type}"
			remote_file = s3.buckets['programs-cropped.nypl.org'].objects[remote_path]

			local_file = File.open(path,'wb') do |f|
				f.puts remote_file.read
			end
		end

		path
	end

	def parse_bbox coords
		coords.map! { |c| c.to_i }

		b_width = coords[2] - coords[0]
		b_height = coords[3] - coords[1]
		ul = [coords[0], coords[1]]
		# b_height = coords[3] - coords[1]
		# ul = [coords[0], height - coords[1] - b_height]

		{:ul => ul, :w => b_width, :h => b_height}
	end

end
