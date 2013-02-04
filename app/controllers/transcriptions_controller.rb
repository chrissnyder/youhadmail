class TranscriptionsController < ApplicationController
  # before_filter CASClient::Frameworks::Rails::Filter, :only => [:new, :index, :edit]
  before_filter :check_or_create_user, :only => [:transcribe, :index, :edit]
  before_filter :get_or_assign_collection, :only => [:next, :transcribe]
  after_filter :clear_session, :only =>[ :create ]
  
  def transcribe
		logger.debug "#{p params}"
		unless params[:id].nil?
			@collection = AssetCollection.find(params[:id])
		else
			@collection = AssetCollection.find(session[:collection_id])
		end
		return redirect_to :root if @collection.nil?
		
    @user = current_user
		render :action => 'transcribe'
  end
  
  def next
    @user = current_user

		if @collection.nil? 
			flash[:notice]= "You have already seen everything"
			redirect_to :root
		end
		render :action => 'transcribe'
  end

  def show
    @transcription = Transcription.find(params[:id])
  end

  def index 
    # @transcriptions = current_user.transcriptions.all
    @transcriptions = current_user.transcriptions.all
  end

  def edit 
    @transcription = Transcription.find(params[:id])
    @asset = @transcription.asset
    @user = current_user
  end
  
  def create 
		transcription = Transcription.find_by_user_id_and_asset_collection_id(current_user.id, params[:collection_id])

		return update unless transcription.nil?

		collection = AssetCollection::find(params[:collection_id])
		transcription = Transcription.create( :user => current_user, :asset_collection => collection)
                                            
    annotations = params[:annotations]
    transcription.add_annotations_from_json(annotations)

    respond_to do |format|
      format.js { render :nothing => true, :status => :created }
    end
  end
  
  
  def update

		transcription = Transcription.find_by_user_id_and_asset_collection_id(current_user.id, params[:collection_id])
		logger.error "ERROR: Count not find transcription to update" unless transcription

		transcription.annotations.delete_all
		transcription.add_annotations_from_json( params[:annotations])

		respond_to do |format|
		format.js { render :nothing => true, :status => :created }
		end
  end

	def by_user
		transcription = Transcription.find_by_user_id_and_asset_collection_id(current_user.id, params[:collection_id])

		respond_to do |format|
			format.json { 	
				render :json => transcription.to_json(:include => { 
					:annotations => { 
						:only => [ :bounds, :data, :entity_id, :asset_id ]
					}
				})
			}
		end    
	end

	def terms
		field_key = params[:field_key]
		typed_term = params[:term]

		common_terms = Annotation
			.where(:entity_id => params[:entity_id], 'data.' + field_key => /#{Regexp.escape(typed_term)}.*/)
			.fields(:data).all

		format.js { render :nothing => true} if common_terms.nil?

		# this is the format that jquery autocomplete expects:
		common_terms.map! { |ann| {:label => ann.data[field_key], :value => ann.data[field_key]} }

		respond_to do |format|
			format.json { 	
				render :json => common_terms
			}
		end
	end
  
  def get_or_assign_collection
    @collection = AssetCollection.find(session[:collection_id])
    unless @collection and @collection.active? 
      @collection = AssetCollection.next_unseen_for_user(current_user) #.try(:asset_collection)
      if @collection
        session[:collection_id] = @collection.id
      end
    end
  end
  
  def get_or_assign_asset
    @asset=Asset.find(session[:asset_id])
    #if we have no asset in the session
    unless @asset
      #try to get a new one from the current collection
      @asset = @collection.next_unseen_for_user current_user
      session[:asset_id] = @asset.id
    end
  end
  
  def clear_session
    [:collection_id].each {|a| session[a]=nil}
  end
end

