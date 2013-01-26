class AssetCollectionsController < ApplicationController

  #refactor this 
  def index 
    @collections = AssetCollection.all.select{|b| b.assets.count>0}
  end
  
  def show
    @collection = AssetCollection.find(params[:id])
    respond_to do |format|
			format.html
			format.json { 	
				render :json => @collection.to_json
			# 	(:include => [:assets]

				# { 
					#:assets
					#=> { 
					#	:only => [ :id, :width, :height], :methods => [:hocr_blocks, :signed_uri.to_s]
					#}
				#})
			#	)
			}
		end    
	end
end
