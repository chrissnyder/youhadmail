task :playbills_bootstrap => :environment do
  Template.delete_all
  Entity.delete_all
  Asset.delete_all
  AssetCollection.delete_all

	Transcription.delete_all
	Annotation.delete_all
 
  template = Template.create( :name => "Playbills Transcription Template",
                              :description => "A template for transcribing playbills",
                              :project => "My great project",
                              :display_width => 600,
                              :default_zoom => 1.5)

	entity_count = 0

	# Title
  entity = Entity.create( 
		:name => "Show Title",
		:description => "",
		:help => 'After entering the official title of the play, other title-like phrases should be flagged as "supplemental".',
		:extended_help => 'The "official" title of the play is the title on the playbill that\'s closest to the title originally penned by the playwrite. Many playbills join "supplemental" title-like phrases to the title like "A play in three acts" or "Second Triumphal Tour". "Official" and "supplemental" titles should be entered seperately.',
		:examples => ["Macbeth", "Madame Sherry", "A French Vaudevill in Three Acts"],
		:multiple => true,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "title",
		:field_key => "title",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "type",
		:field_key => "type",
		:kind => "select",
		:options => { :select => ['official','supplemental'] }
	)
  template.entities << entity

	# Dates
  entity = Entity.create( 
		:name => "Show Date",
		:description => "The date(s) the show performed",
		:help => "If given, show dates tend to apear on the first page",
		:examples => ["September 25, 1911"],
		:resizeable => false,
		:multiple => false,
		:order => entity_count+=1
	)
	entity.fields << Field.new( 
		:name => "date opened",
		:field_key => "date_opened",
		:kind => "date")
	entity.fields << Field.new(
		:name => "date closed",
		:field_key => "date_closed",
		:kind => "date")
  template.entities << entity

	# Theatre 
  entity = Entity.create( 
		:name => "Theatre Name",
		:description => "",
		:help => "Theatre names tend to appear on the first page near the top",
		:examples => ["Teller's Broadway Theatre", "Booth Theatre"],
		:multiple => false,
		:order => entity_count+=1
	)
	entity.fields << Field.new( 
		:name => "theatre",
		:field_key => "theatre",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  template.entities << entity
	
	# Location
  entity = Entity.create( 	
		:name => "Location",
		:description => "The street address of the theatre",
		:help => "The address is typically in the head of the first page. ",
		:extended_help => "The address is typically in the head of the first page. If all that's given is an intersection, go ahead and enter that; We'll do the data scrubbing later.",
		:examples => ["123 Wooster St", "Broadway and Myrtle"],
		:resizeable => false,
		:multiple => false,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "theatre",
		:field_key => "theatre",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  template.entities << entity
 	
	# Cast Member
  entity = Entity.create( 
		:name => "Cast Member",
		:description => "An actor or actress in the show",
		:help => "Look for lines of the form \"[character] ... [actor]\".",
		:extended_help => "Look for lines of the form \"[character] ...... [actor]\".\n\nFrequently roles are given a unique description like \"porter\", \"Kat's husband\", or \"a nurse\". Other times, several roles will be categorized, such as \"Troopers\" or \"Mr. Faraday's Daughters\". When such descriptions appear, enter them in the description field.",
		:examples => [["Lulu", "an actress", "Miss Alice Parker"], ["Phillippe", "janitor (Kat's husband)", "Mr. Sherman Wade"]],
		:multiple => true,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "Character",
		:field_key => "character",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "Description",
		:field_key => "description",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "Actor",
		:field_key => "actor",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
  template.entities << entity
  
	# Production Staff
  entity = Entity.create( 
		:name => "Production Staff",
		:description => "A person credited with offstage support",
		:help => "Production staff typically appear on the first page.",
		:extended_help => "Production staff typically appear on the first page. Try to find a matching role in the drop-down. This may require re-wording the role that appears (e.g. \"wrote the book\" corresponds to role \"author\", \"composed the music\" should be entered as \"composer\")",
		:examples => [["Manager", "Leo C. Teller"], ["Music","Hugo Felix"], ["Playwrite", "Edward Knoblock"]],
		:resizeable => false,
		:multiple => true,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "role",
		:field_key => "role",
		:kind => "text",
		:vocab => [
			'Producer',
			'Director',
			'Playwright',
			'Scenic designer',
			'Lighting designer',
			'Sound designer',
			'Production manager',
			'Technical Director',
			'Show control designer',
			'Theatrical technician'
		],
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "name",
		:field_key => "name",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
  template.entities << entity

	# Advertisments
  entity = Entity.create( 
		:name => "Advertisement",
		:description => "An advertisement for local goods or services.",
		:help => "Your box should enclose the whole advertising block",
		:examples => [["Sohmer", "315 Fifth Ave., cor. 32d St", "pianos"]],
		:multiple => true,
		:order => entity_count+=1
	)
	entity.fields << Field.new( 
		:name => "company",
		:field_key => "company",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 100, :min_length => 0 } }
	)
	entity.fields << Field.new( 
		:name => "address",
		:field_key => "address",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 100, :min_length => 0 } }
	)
	entity.fields << Field.new( 
		:name => "principal product / service",
		:field_key => "goods",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 100, :min_length => 0 } }
	)
  template.entities << entity




  template.save 

  #generate a single asset and a single user for testing just now
  playbill = AssetCollection.create(:title => "Playbill 1", :author => "", :extern_ref => "http://google.com", :template => template)

=begin
 	public/images/00024.jpg JPEG 1000x1497 1000x1497+0+0 8-bit PseudoClass 256c 556KB 0.000u 0:00.000
	public/images/00025.1.jpg[1] JPEG 1000x1534 1000x1534+0+0 8-bit PseudoClass 256c 523KB 0.000u 0:00.000
	public/images/00025.2.jpg[2] JPEG 1000x1534 1000x1534+0+0 8-bit PseudoClass 256c 581KB 0.000u 0:00.000
	public/images/00026.1.jpg[3] JPEG 1000x1537 1000x1537+0+0 8-bit PseudoClass 256c 491KB 0.000u 0:00.000
	public/images/00026.2.jpg[4] JPEG 1000x1537 1000x1537+0+0 8-bit PseudoClass 256c 553KB 0.000u 0:00.000
=end

  Asset.create(:uri => "https://s3.amazonaws.com/programs-cropped.nypl.org/10/00030.jpg", :display_width => 1000, :height => 1537, :width => 1000, :asset_collection => playbill, :order => 0)
  Asset.create(:uri => "https://s3.amazonaws.com/programs-cropped.nypl.org/10/00031.1.jpg", :display_width => 1000, :height => 1540, :width => 1000, :asset_collection => playbill, :order => 1)
  Asset.create(:uri => "https://s3.amazonaws.com/programs-cropped.nypl.org/10/00031.2.jpg", :display_width => 1000, :height => 1540, :width => 1000, :asset_collection => playbill, :order => 2)
=begin
  Asset.create(:location => "/images/00024.jpg", :display_width => 800, :height => 1497, :width => 1000, :template => template, :asset_collection => playbill)
  Asset.create(:location => "/images/00025.1.jpg", :display_width => 800, :height => 1534, :width => 1000, :template => template, :asset_collection => playbill)
  Asset.create(:location => "/images/00025.2.jpg", :display_width => 800, :height => 1534, :width => 1000, :template => template, :asset_collection => playbill)
  Asset.create(:location => "/images/00026.1.jpg", :display_width => 800, :height => 1537, :width => 1000, :template => template, :asset_collection => playbill)
  Asset.create(:location => "/images/00026.2.jpg", :display_width => 800, :height => 1537, :width => 1000, :template => template, :asset_collection => playbill)

=end

  # Asset.create(:location => "/images/1.jpeg", :display_width => 800, :height => 2126, :width => 1388, :template => template, :asset_collection => playbill)
  # Asset.create(:location => "/images/2.jpeg", :display_width => 800, :height => 2107, :width => 1380, :template => template, :asset_collection => playbill)

  
end
