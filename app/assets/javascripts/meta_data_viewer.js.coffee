class MetaDataViewer

	constructor:(el)->
		@list = $(el).append("<ul class='MetaDataViewer'></ul>")

	render:=>
		@renderMapsPane()
		@rendePhotosPane()
		@renderBiosPane()

	renderMapsPane:=>
		@renderPane("maps")

	renderPhotosPane:=>
		@renderPane("maps")
	
	renderBiosPane:=>
		@renderPane("maps")
	
	renderPage:(name)=>
		@el.append("<li class='metaPane #{name}'><h3>#{name}</h3></li>")

window.MetaDataViewer = MetaDataViewer