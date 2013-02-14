task :you_had_mail_bootstrap => :environment do
  Template.delete_all
  Entity.delete_all
  # Asset.delete_all
  # AssetCollection.delete_all

	Transcription.delete_all
	Annotation.delete_all

	AssetCollection.delete_all
	Asset.delete_all
 	
  template = Template.create( :name => "You Had Mail Template",
                              :description => "A template for you had mail",
                              :project => "My great project",
                              )

	entity_count = 0

	# To
  entity = Entity.create( 
		:name => "To",
		:description => "Who is this letter to?",
		:category => "Person",
		:help => 'This is usually found after the word "Dear" in the letter near the top.',
		:extended_help => '',
		:examples => ["Herschel"],
		:multiple => false,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "Title",
		:field_key => "title",
		:kind => "text",
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "First Name",
		:field_key => "first_name",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "Last Name",
		:field_key => "last_name",
		:kind => "text",
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  template.entities << entity

	# From
  entity = Entity.create( 
		:name => "From",
		:description => "Who is this letter from?",
		:category => "Person",
		:help => "Who is this letter from.",
		:examples => ["Herschel"],
		:multiple => false,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "Title",
		:field_key => "title",
		:kind => "text",
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
	entity.fields << Field.new( 
		:name => "First Name",
		:field_key => "first_name",
		:kind => "text",
		:options => { :text => { :max_length => 120, :min_length => 0 }}
	)
	entity.fields << Field.new(
		:name => "Last Name",
		:field_key => "last_name",
		:kind => "text",
		:options => { :text => { :max_length => 120, :min_length => 0 }})
  template.entities << entity

	# Mentioned
  entity = Entity.create( 
		:name => "Mentioned",
		:description => "Someone mentioned in the letter",
		:category => "Person",
		:help => 'This is a person mentioned in the letter other than the sender and the recipient',
		:extended_help => '',
		:examples => ["Herschel"],
		:multiple => false,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "Title",
		:field_key => "title",
		:kind => "text",
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "First Name",
		:field_key => "first_name",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "Last Name",
		:field_key => "last_name",
		:kind => "text",
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  template.entities << entity


	# Dates 
  entity = Entity.create( 
		:name => "Dates",
		:description => "Any dates you can find on the letter",
		:category => "Dates & Locations",
		:help => "We are looking for dates the letter was sent or  recived ",
		:examples => [],
		:multiple => true,
		:order => entity_count+=1
	)
	entity.fields << Field.new( 
		:name => "Date type",
		:field_key => "type",
		:vocab => 'suggest-common',
		:kind => "select",
		:options => { :select => ['Sent','Recived', 'other'] }
	)
	entity.fields << Field.new( 
		:name => "Date",
		:field_key => "date",
		:vocab => 'suggest-common',
		:kind => "date"
	)
  template.entities << entity
	
	# Subject
  entity = Entity.create( 	
		:name => "Subject",
		:description => "The subject of the letter",
		:category => "Content",
		:help => "Is there a subject or can you give a general subject for the letter",
		:extended_help => "The address is typically in the head of the first page. If all that's given is an intersection, go ahead and enter that; We'll do the data scrubbing later.",
		:examples => ["The need for laws", "My favourite ponies"],
		:multiple => false,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "Subject",
		:field_key => "subject",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 120, :min_length => 0 } }
	)
  template.entities << entity
 	
	# Locations
  entity = Entity.create( 
		:name => "Locations",
		:description => "Where was this letter address to or from? Or any other location you can find in the document.",
		:category => "Dates & Locations",
		:help => "This can be on the top of the letter or on the envelope.",
		:extended_help => "",
		:examples => "",
		:multiple => true,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "Street Address",
		:field_key => "street_address",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "City",
		:field_key => "city",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
  entity.fields << Field.new( 
		:name => "Provence",
		:field_key => "provence",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)

	entity.fields << Field.new( 
		:name => "Postal Code",
		:field_key => "postal_code",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 50, :min_length => 0 } }
	)
	entity.fields << Field.new( 
		:name => "Country",
		:field_key => "country",
		:kind => "text",
		:vocab => 'suggest-common',
		:options => { :text => { :max_length => 200, :min_length => 0 } }
	)
	entity.fields << Field.new( 
		:name => "Type",
		:field_key => "type",
		:kind => "select",
		:options => { :select => ['From','To','Mentioned'] }
	)
  template.entities << entity
  
	# Summary
  entity = Entity.create( 
		:name => "Summary",
		:description => "A summary of the letter",
		:category => "Content",
		:help => "Give a breif summary of the letter",
		:extended_help => "This is a very subjective thing",
		:examples => ["This is a letter about the benefits of whisky."],
		:multiple => false,
		:order => entity_count+=1
	)
  entity.fields << Field.new( 
		:name => "Summary",
		:field_key => "summary",
		:kind => "text",
		:options => { :text => { :max_length => 500, :min_length => 0 } }
	)
  
  template.entities << entity

	
template.save 

=begin
begin
  #generate a single asset and a single user for testing just now
  playbill = AssetCollection.create(:title => "Test Letter", :author => "", :extern_ref => "http://google.com", :template => template)

  Asset.create(:uri => "/example_assets/AlvanClark_X7_1_1.jpg", :display_width => 1275, :height => 1650, :width => 1275, :asset_collection => playbill, :order => 0)
  Asset.create(:uri => "/example_assets/AlvanClark_X7_1_2.jpg", :display_width => 1275, :height => 1650, :width => 1275, :asset_collection => playbill, :order => 1)
  Asset.create(:uri => "/example_assets/AlvanClark_X7_1_3.jpg", :display_width => 1275, :height => 1650, :width => 1275, :asset_collection => playbill, :order => 2)
end

 	public/images/00024.jpg JPEG 1000x1497 1000x1497+0+0 8-bit PseudoClass 256c 556KB 0.000u 0:00.000
	public/images/00025.1.jpg[1] JPEG 1000x1534 1000x1534+0+0 8-bit PseudoClass 256c 523KB 0.000u 0:00.000
	public/images/00025.2.jpg[2] JPEG 1000x1534 1000x1534+0+0 8-bit PseudoClass 256c 581KB 0.000u 0:00.000
	public/images/00026.1.jpg[3] JPEG 1000x1537 1000x1537+0+0 8-bit PseudoClass 256c 491KB 0.000u 0:00.000
	public/images/00026.2.jpg[4] JPEG 1000x1537 1000x1537+0+0 8-bit PseudoClass 256c 553KB 0.000u 0:00.000
=end
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
