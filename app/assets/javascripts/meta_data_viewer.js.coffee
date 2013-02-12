class MetaDataViewer

  constructor:(el)->
    @el = $(el)
    @list = $("<ul class='mediaTypes'></ul>")
    @el.append(@list)

  
  select:(type)=>
    console.log "type is #{typeof(type)}"
    if typeof(type) is "object"
      type = $(type.currentTarget).data().type

    $('.metaPane').removeClass("active")
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



  geoCode:(name)=>
    viewbox = "viewbox=#{[-2.649830, 53.435829, -5.413860, 51.374550].join(',')}&bounded=1"
    $.getJSON "http://nominatim.openstreetmap.org/search/#{name}?format=json&countrycodes=gb&json_callback=?",(results)=>
      if results.length > 0
        @map.panTo new L.LatLng(results[0].lat, results[0].lon)
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
    toImage = "<img src='http://upload.wikimedia.org/wikipedia/commons/thumb/0/01/1891_AlvanClark_Boston.png/220px-1891_AlvanClark_Boston.png'></img>"
    toBlurb = "Alvan Clark (March 8, 1804 – August 19, 1887), born in Ashfield, Massachusetts, the descendant of a Cape Cod whaling family of English ancestry,[1] was an American astronomer and telescope maker. He was a portrait painter and engraver (ca.1830s-1850s), and at the age of 40 became involved in telescope making."
    
    to = $("<div class='bio to'></div>")
    to.append(toImage).append(toBlurb)
    from =""
    @biosPane.append(to)
    @biosPane.append(from)


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