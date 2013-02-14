class MetaDataViewer

  constructor:(el)->
    @el = $(el)
    @list = $("<ul class='mediaTypes'></ul>")
    @el.append(@list)

  
  select:(type)=>
    if typeof(type) is "object"
      type = $(type.currentTarget).data().type

    $('.metaPane').removeClass("active")
    $(".metaPane.#{type}").removeClass("pulse")
    $(".metaPane.#{type}").addClass("active")

  render:=>
    @renderMapsPane()
    @renderPhotosPane()
    @renderBiosPane()

    @select("Maps")

  renderMapsPane:=>
    @mapsPane = @renderPane("Maps")
    @mapsPane.append("<div style='width:355px; height:305px' id='letterMap'></div>")
    setTimeout @setUpMap , 200


  dealWithAnnotation:(annotation, entity)=>
    switch annotation.entity_name 
      when "To"
        console.log "DOING TO ", annotation
        name = annotation.data.first_name + " " + annotation.data.last_name
        @addPerson( name, "to" )

      when "From" 
        console.log "DOING From ", annotation
        name = annotation.data.first_name + " " + annotation.data.last_name
        @addPerson( name, "to" )

      when "Locations"
        console.log "DOING LOCATIONS"
        values =  (val for key ,val of annotation.data)
        @geoCode values.join(" "), (result)=>
          @addToMap(result)

  addToMap:(location)=>
    $(".metaPane.Maps").addClass("pulse")
    # Icon = L.Icon({ iconUrl: '/assets/marker-icon.png', shadowUrl: '/assets/marker-shadow.png'})
    marker = new L.Marker(location)
    @map.addLayer marker


  addPerson:(name)=>
    $.getJSON "/bio?q=#{name}", (result)=>
      $(".metaPane.Bios").addClass("pulse")
      @biosPane.append @bioFromWiki(result, "to")


  bioFromWiki:(wiki,role)=>
    r = $("<div class='bio #{role}'></div>")
    r.append $("<img src='#{wiki.image}'></img>")
    r.append $(wiki.excerpt)


  geoCode:(name,cb)=>
    console.log "trying to find #{name}"
    $.getJSON "http://nominatim.openstreetmap.org/search/#{name}?format=json&json_callback=?",(results)=>
      if results.length > 0
        loc =  new L.LatLng(results[0].lat, results[0].lon)
        @map.panTo loc
        cb  loc if cb?
      else 
        alert("count not find #{name}")

  setUpMap:=>

    @map = new L.Map 'letterMap',
      maxZoom: 19
      scrollWheelZoom: false

    @baseLayer = new L.TileLayer 'http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      maxZoom: 18
    
    @map.addLayer @baseLayer

    @map.setView(new L.LatLng(53.283333,-4.333333),5);
    @map.invalidateSize()

  renderPhotosPane:=>
    @photosPane = @renderPane("Photos")
  
  renderBiosPane:=>
    @biosPane = @renderPane("Bios")
    
    # bio = "Alvan Clark (March 8, 1804 – August 19, 1887), born in Ashfield, Massachusetts, the descendant of a Cape Cod whaling family of English ancestry,[1] was an American astronomer and telescope maker. He was a portrait painter and engraver (ca.1830s-1850s), and at the age of 40 became involved in telescope making."
    # wiki_link = "http://en.wikipedia.org/wiki/Alvan_Clark"
    # toImage = "<img src='http://upload.wikimedia.org/wikipedia/commons/thumb/0/01/1891_AlvanClark_Boston.png/220px-1891_AlvanClark_Boston.png'></img>"
    # toBlurb = "<p>#{bio[0..150]}<a target=_blank href='#{wiki_link}'>...</a></p>"
    
    # to = $("<div class='bio to'></div>")
    # to.append(toImage).append(toBlurb)
    # from = ''
    # @biosPane.append(to)
    # @biosPane.append(from)


  renderPane:(name)=>
    console.log "redering #{name}"
    content = $("<div class='metaContent'></div>")
    pane = $("<li data-type=#{name} class='metaPane #{name}'></li>")
    pane.on 'click', @select
    pane.append("<h3>#{name}</h3>")
    pane.append(content)

    @list.append(pane)
    content

window.MetaDataViewer = MetaDataViewer