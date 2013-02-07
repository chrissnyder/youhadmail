class AnnotationsController < ApplicationController
  # before_filter CASClient::Frameworks::Rails::Filter, :only => [:new, :index, :edit]
  before_filter :check_or_create_user, :only => [:transcribe, :index, :edit]
  before_filter :get_or_assign_collection, :only => [:next, :transcribe]
  # after_filter :clear_session, :only =>[ :create ]
 
 	def index
    @collection = AssetCollection.find(params[:asset_collection_id])
		annotations = @collection.annotations

		respond_to do |format|
			format.json { 	
				render :json => annotations.to_json
			}
		end    
	end

 
end 
