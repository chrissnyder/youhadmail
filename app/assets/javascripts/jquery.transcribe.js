$.widget("ui.transcribe", {

	options									: {	
		annotationBoxWidth  							: 500,
		annotationBoxHeight 							: 250,
		zoomLevel					 								: 1,

		zoomBoxWidth											: 500,
		zoomBoxHeight 										: 200,
		markerIcon       									: '/images/annotationMarker.png',
		orientation 											: "floatAbove",
		modalDefaultTitle									: 		'What kind of text is this?',

		onSaveSuccess											: null,
		onSaveFail												: null,
		onAnnotationAdded  								: null,
		onAnnotationRemoved 							: null,
		onAnnotationUpdated								: null,
		onAnnotationEditedStarted 				: null,

		authenticity_token 								: null,

		image							 								: null,
		page_data					 								: {},
		update						 								: false,

		maxImageWidth											: null,				// Max size to display asset; Defaults to size of element

		showNav														: true,				// Whether or not to show nav for multi-asset doc
		navWidth													: 170,				// Nav width
		navPadding												: {right: 20, bottom: 10},		// Padding to show next to and below nav

	},

	/* Begin: Public Methods */

	deleteAnnotation				: function (annotation_id){
														if(this.annotations[annotation_id].marker_element)
															this.annotations[annotation_id].marker_element.remove();
														this.annotations[annotation_id] = null;
														this._trigger('anotationDeleted',{},"message deleting"+annotation_id)
														if(this.options.onAnnotationRemoved!=null) {
															this.options.onAnnotationRemoved.call(this, annotation_id);
														}
														  
	},

	editAnnotation					: function (annotation_id) {
														var annotation = this.annotations[annotation_id];
														this.showAsset(annotation.asset_id);
														this.editing_id = annotation_id;

														this._trigger('anotationEdited',{},"message editing"+annotation_id)
														if(this.options.onAnnotationEditedStarted!=null){
															// console.log('onAnnotationEditedStarted: ' + annotation_id);
															this.options.onAnnotationEditedStarted.call(this,{annotation_id:annotation_id, data:annotation});
													 	}
														this._showBoxWithAnnotation(annotation);
	},

	/*
	*		Get cleaned annotations (remove deleted annotations and strip ephemeral properties)
	*/
	getAnnotations        	: function() { 
														var ret = [];

														// Ensure removed annotations aren't included
														for(var id in this.annotations) {
															var ann = this.annotations[id];
															if (ann != null) {
																var cleaned = {
																	asset_id: ann.asset_id,
																	bounds: ann.bounds,
																	data: ann.data,
																	entity_id: ann.entity_id
																};
																ret.push(cleaned);
															}
														}
														return ret;
	},

	_modalMoveToLine				: function(steps) {
														
														var nextLine = this._getNextLine(steps);
														var coords = this._linesCoords([nextLine]);
														coords = this._denormalizeBounds(coords);
														coords.x += coords.width / 2;
														coords.y += coords.height / 2;
														this._showBox(coords);

	},

	_modalAddLine				: function() {
														var lines = this._linesInView();
														var nextLine = this._getNextLine(1);
														if(!nextLine) return;

														lines.push(nextLine);
														var coords = this._linesCoords(lines);
														coords = this._denormalizeBounds(coords);
														coords.x += coords.width / 2;
														coords.y += coords.height / 2;
														this._showBox(coords);

	},

	_modalUpdateZoomControls: function() {

														if(!this._getNextLine(1)) {
															$('.button-add-next-line').addClass('disabled');
															$('.button-next-line').addClass('disabled');
														} else {
															$('.button-add-next-line').removeClass('disabled');
															$('.button-next-line').removeClass('disabled');
														}
														if(!this._getNextLine(-1)) {
															$('.button-previous-line').addClass('disabled');
														} else {
															$('.button-previous-line').removeClass('disabled');
														}
	},

	_getNextLine						: function(steps) {
	
														var linesOrdered = this.assets[this.assetIndex].lines.sort(function(l1, l2) {
															if(l1.coords.y > l2.coords.y) return 1;
															return -1;
														});

														var lines = this._linesInView();
														if(lines.length == 0) {

															var percentView = this._normalizeBounds(this._currentCoords());

															for(var i=0;i<linesOrdered.length;i++) {
																var l = linesOrdered[i];
																if(l.coords.y >= percentView.y) {
																	lines = [l];
																	break;
																}
															}
														}
														console.log("in view: %o",lines);
														var selectedLine;
														if(steps > 0)
															selectedLine = lines.pop();
														else
															selectedLine = lines.shift();

														var nextLine = false;
														for(var i=0;i<linesOrdered.length;i++) {
															var l = linesOrdered[i];
															if(l.id == selectedLine.id) {
																var index = i + steps;
																if(index >= 0 && index < linesOrdered.length) {
																	nextLine = linesOrdered[index];
																	break;
																}
															} 
														}
														if(!nextLine)
															console.log("Couldn't find line " + steps + ' steps after ', selectedLine);
														
														return nextLine;
	},

	showAsset								: function(id) {

														for(var i=0;i<this.assets.length;i++) {

															if(this.assets[i].id != id) continue;

															this.assetIndex = i;

															$('.transcribe-image-holder > img').hide();
															$('.transcribe-image-holder .hocr-line').hide();

															for(var id in this.annotations) {
																if (this.annotations[id] != null) {
																	var ann = this.annotations[id];
																	if(ann.marker_element) {
																		if(ann.asset_id != id) {
																			ann.marker_element.hide();
																		} else
																			ann.marker_element.show();
																	}
																}
															}


															// Update zoom box
															var imageWidth = this.assets[this.assetIndex].displayWidth * this.options.zoomLevel;
															var imageHeight = this.assets[this.assetIndex].displayHeight * this.options.zoomLevel;
															this.transcribeModal.zoomBox.find('#transcribe-zoom-box-image-holder')
																.css({
																	width: imageWidth,
																	height:imageHeight
																})
																.find('img')
																	.attr('src', this.assets[this.assetIndex].uri)
																	.css({width: '100%', height:'100%'});

															// Update main image
															this.assets[this.assetIndex].element.show();
															var hocrLines = this.assets[this.assetIndex].lines;
															for(var i=0;i<hocrLines.length;i++) {
																hocrLines[i].element.show();
																hocrLines[i].zoomElement.show();
															}

															this.element.find('.transcribe-page-nav').css('height', this.assets[this.assetIndex].displayHeight);

															break;
														}
	},

	showHelp 								: function(entityId) {
														var entity;
														if(entity = this._entityById(entityId)) {
															var text = '';

															$('.transcribe-full-help').remove();

															var help = $('<div class="transcribe-full-help"></div>');
															if(entity.help || entity.extended_help)
																help.html('<p>' + (entity.extended_help ? entity.extended_help : entity.help).replace(/\n/, '</p><p>') + '</p>');
															if(entity.examples) {
																var examples = $('<ul></ul>');
																for(var i=0;i<entity.examples.length;i++) {
																	var ex = entity.examples[i];
																	if($.type(ex) == 'array') {
																		text = ex.join(',&nbsp;&nbsp;&nbsp;');
																	} else {
																		text = ex;
																	}
																	examples.append($('<li>' + text + '</li>'));
																}
																help.append($('<h2>Examples</h2>')).append(examples);
															}

															this.dialog
																.append(help)
																.data('dialog')
																	.option('title', entity.name + ' Help')
																	.open();
														}
	},

	save: function(url){ 

													var finalAnnotations = this.getAnnotations();

													// huh? 
													// this._trigger('resultsSubmited',{},this.annotations);

													var data = {};
													for(var k in this.options.additionalSaveParams)
														data[k] = this.options.additionalSaveParams[k];

													data.annotations = finalAnnotations;
													data.authenticity_token = this.options.authenticity_token;

													type =	this.options.update ? "PUT" : "POST"
													$.ajax({
														url: url,
														data: data,
														type: type,
														success: jQuery.proxy(this._saveSucceeded, this),
														error: jQuery.proxy(this._saveFailed, this)
													});

	},

	setAnnotations					: function(annotations) {
														this.annotations = [];
														for(var i=0;i<annotations.length;i++) {
															var ann = annotations[i];
															ann.id = i;
															this.annotations[ann.id] = ann;
														}
														this.annIdCounter = i;

														for(var id in this.annotations){
															var bounds = this.annotations[id].bounds;
															
															this.annotations[id].marker_element = this._generateMarker(this._denormalizeBounds(bounds), id);
															if (this.options.onAnnotationAdded!=null){
																this.options.onAnnotationAdded.call(this, this.annotations[id]);
															}
														}
	},



	/* PRIVATE */

	_create 								: function() {
														var self= this;

														this.element.find('.loading').remove();

														// Try to prevent selectable text to mitigate issues while dragging
														this.element.find('p, div, img')
															.attr('unselectable', 'on')
															.css('user-select', 'none')
															.on('selectstart', false);


														this.assets = this.options.assets;
														this.annotations = [];

														this.element.css("width",this.options.assetScreenWidth)
																				.css("height",this.options.assetScreenHeight)
																				.css("position","relative");
														this.imageElements = [];
														this.hocrElements = [];
														this.assetIndex = 0;
														this.selectedLines = [];


														// Build page nav
														var ul = $('<ul class="transcribe-page-nav"></ul>').css('width',this.options.navWidth);
														for(var i=0;i<this.assets.length;i++) {
															var _asset = this.assets[i];
															var img = $('<img/>').attr('src',_asset.thumb_uri).css('width',this.options.navWidth - 20); // sub 20 for scrollbar
															var li = $('<li></li>').css('padding-bottom',this.options.navPadding.bottom)
																.append(img.click(this.showAsset.bind(this, _asset.id)));
															ul.append(li);
														}
														this.element.append(ul);

														if(this.options.maxImageWidth == null) {
															this.options.maxImageWidth = this.element.width();
															if(this.options.showNav) {
																this.options.maxImageWidth -= (this.options.navPadding.right + this.options.navWidth);
															}
														}

														// Build central image view
														this.element.append($('<div class="transcribe-image-holder"></div>'));
														for(var i=0;i<this.assets.length;i++) {
															var asset = this.assets[i];
															asset.displayWidth = Math.min(asset.width, this.options.maxImageWidth);
															asset.displayHeight = Math.round(asset.height * (this.options.maxImageWidth / asset.width));

															asset.element = $("<img></img>")
																				 .attr("src", asset.uri)
																				 .css("width", asset.displayWidth)
																				 .css("height",asset.displayHeight)
																				 .css("position","relative")
																				 .css("margin", "0px auto")
																				 .css("left","0px")
																				 .css("top","0px");
															if(i == 0)
																asset.element.load(function() {
																	console.log('first asset loaded');
																});

															asset.element.imgAreaSelect({
																handles: false,
																autoHide : true,
																onSelectEnd: function render_options(img, box){
																	var midX=(box.x1+box.x2)/2.0;
																	var midY=(box.y1+box.y2)/2.0;
																	
																	if(box.width == 0 || box.height == 0) return;

																	self._showBox({x:midX, y:midY, width:box.width, height:box.height});
																}
															});

															this.imageElements.push(asset.element);
															this.element.find('.transcribe-image-holder').append(asset.element);

															// Add Hocr lines
															this._createHocrElements(asset);
														}

														this.element.append(this.images);


														// Create hocr-line selector bounding box
														this.lineBoundingBox = $('<div class="transcribe-line-bounding-box"><div class="transcribe-color-overlay"></div></div>')
															.appendTo(this.element.find('.transcribe-image-holder'));
														var controls = $('<div class="transcribe-line-bounding-box-controls"></div>')
															.append($('<span class="transcribe-line-bounding-box-message"></span>'))
															.append($('<a href="javascript:void(0);">Transcribe →</a>').click(this._transcribeSelectedLines.bind(this)));
														this.lineBoundingBox.append(controls);
														this.lineBoundingBox.append(
															$('<span class="ui-icon ui-icon-circle-close large"></span>')
																.click(this._deselectSelectedLines.bind(this))
														);

														// Bind Save button
														if(this.options.doneButton && this.options.submitURL){
															this.options.doneButton.click(jQuery.proxy(function(event){
																event.preventDefault();
																this.save(this.options.submitURL);
															},this))
														}
														
														// Create transcription modal
														this.transcribeModal = this._generateTranscribeModal();
														this.element.find('.transcribe-image-holder').append(this.transcribeModal);

														// Create help dialog
														this.dialog = $('<div></div>').dialog({
															autoOpen: false,
															width: 500,
															closeOnEscape: true,
															title: "Help"
														}).hide()


														this.element.click(function(event){
															event.preventDefault();
														});

														this.editing_id = null;


														// Show first image
														this.showAsset(this.assets[0].id);

	},


	/* Begin: UI Utils */

	_checkAndSwitchOrientation : function(position){
														if (this.options.orientation == "floatUnder" && position.y > this.assets[this.assetIndex].displayHeight/2){
															this.options.orientation="floatAbove";
															$(".transcribe-form-holder").animate({"top":"-="+(this.options.zoomBoxHeight +this.options.annotationBoxHeight )},500);
														}
														
														if (this.options.orientation == "floatAbove" && position.y < this.options.assetScreenHeight/2){
															this.options.orientation="floatUnder";
															$(".transcribe-form-holder").animate({"top":"+="+(this.options.zoomBoxHeight+this.options.annotationBoxHeight)},500);
														}
													
	},

	_currentCoords					: function() {
														var ul = $('#transcribe-zoom-box-image-holder').position();
														// console.log('... determining pos', ul, ul.left / this.options.zoomLevel, ul.top / this.options.zoomLevel);
														return {
															x: ul.left * -1 / this.options.zoomLevel,
															y: ul.top * -1 / this.options.zoomLevel,
															width: parseInt(this.transcribeModal.zoomBox.css('width')) / this.options.zoomLevel,
															height: parseInt(this.transcribeModal.zoomBox.css('height')) / this.options.zoomLevel
														};
														return {
															ul: [
																ul.left * -1 / this.options.zoomLevel,
																ul.top * -1 / this.options.zoomLevel,
															],
															w: parseInt(this.transcribeModal.zoomBox.css('width')) / this.options.zoomLevel,
															h: parseInt(this.transcribeModal.zoomBox.css('height')) / this.options.zoomLevel
														};
	},

	_currentInputs					: function() {
														var fieldset = $('div#transcribe_fieldset_' + this.currentEntityId);
														var inputs = fieldset.find('input, select');
														return inputs;
	},

	_denormalizeBounds 			: function(bounds, toWhat) {
														var toWhat = (typeof toWhat=='undefined')?'asset':'zoomed-asset';
														var scaleFactor = (toWhat=='zoomed-asset'?this.options.zoomLevel:1)
														console.log('scale factor: ' + scaleFactor);

														var assetWidth = this.assets[this.assetIndex].displayWidth * scaleFactor;
														var assetHeight = this.assets[this.assetIndex].displayHeight * scaleFactor;
														var denorm = {width  : bounds.width * assetWidth, 
																					height : bounds.height * assetHeight,
																					x 		 : bounds.x * assetWidth,
																					y 		 : bounds.y * assetHeight,
																					zoom_level : bounds.zoomLevel}
														return denorm;
	},

	_deselectSelectedLines	: function() {
														var lines = this.selectedLines;
														while(line = this.selectedLines.shift()) {
															line.element.trigger('click');
														}
	},

	_dismissAnnotationBox  	: function(){
														this.imageElements[this.assetIndex].imgAreaSelect({disable:false});
														if (this.editing_id!=null){
															var annotation_data=this.annotations[this.editing_id];
															if (this.options.onAnnotationUpdated!=null){
																this.options.onAnnotationUpdated.call(this, {annotation_id:this.editing_id, data:annotation_data});
															}
															this.editing_id=null;
														}	
														this._hideBox();

														this.transcribeModal.find('div.transcribe-entity-fieldsets input[type=text]').val('');

														this._deselectSelectedLines();
	},


	_hideBox								: function() { 
														this.transcribeModal.hide(); 
														$('.darkening-overlay').hide();
														$('.transcribe-modal-containment').hide();
	}, 

	_highlightLinesInside		: function() {

	},

	_hocrLineClicked				: function(l, forceSelected) {
														if(typeof forceSelected == 'boolean' && forceSelected)
															l.selected = true;
														else 
															l.selected = typeof l.selected == 'undefined' ? true : !l.selected;

														if(l.selected) {
															l.element.addClass('selected');
															this.selectedLines.push(l);

														} else {
															l.element.removeClass('selected');
															this.selectedLines = $.grep(this.selectedLines, function(_l) { return _l.id != l.id; });
														}

														// All deselected? hide
														if(this.selectedLines.length == 0) {
															this.lineBoundingBox.hide();

														// ..Otherwise, create bounding box around all lines:
														} else {
															var coords = this._linesCoords(this.selectedLines); 

															this.lineBoundingBox.css({
																left: coords.x * this.assets[this.assetIndex].displayWidth,
																top: coords.y * this.assets[this.assetIndex].displayHeight,
																width: coords.width * this.assets[this.assetIndex].displayWidth,
																height: coords.height * this.assets[this.assetIndex].displayHeight
															}).show();

															this.lineBoundingBox.find('.transcribe-line-bounding-box-message')
																.text(this.selectedLines.length + ' line' + (this.selectedLines.length!=1?'s':'') + ' selected');
														}
	},

	_linesCoords		: function(lines) {
														var bbox = {
															x1: lines[0].coords.x,
															y1: lines[0].coords.y,
															x2: lines[0].coords.x + lines[0].coords.width,
															y2: lines[0].coords.y + lines[0].coords.height,
														};
														for(var i=1;i<lines.length;i++) {
															var c = lines[i].coords;
															bbox.x1 = Math.min(bbox.x1, c.x);
															bbox.y1 = Math.min(bbox.y1, c.y);

															bbox.x2 = Math.max(bbox.x2, c.x + c.width);
															bbox.y2 = Math.max(bbox.y2, c.y + c.height);
														}

														return {
															x: bbox.x1,
															y: bbox.y1,
															width: bbox.x2 - bbox.x1,
															height: bbox.y2 - bbox.y1
														};
														return bbox;
	},
	
	_hocrLineDoubleClicked	: function(l) {
														console.log('clicked %o', l.id.substring(l.id.length-2));
														this._hocrLineClicked(l, true);
														this._transcribeSelectedLines();
	},

	_linesInView 						: function() {
														var ret = [];
														var lines = this.assets[this.assetIndex].lines;
														for(var i=0;i<lines.length;i++) {
															var l = lines[i];
															// console.log('checking boundary of %o', l.id.substring(l.id.length-2));
															if(this._inView(l.coords)) {
																ret.push(l);
															}
														}
														return ret;
	},

	_inView									: function(coords) {

														var asset = this.assets[this.assetIndex];
														var view = this._currentCoords();
														// console.log('... current view: ', view);

														var percentView = this._normalizeBounds(view);

														var fudge = 0.01;
														percentView = {
															x: percentView.x - fudge,
															y: percentView.y - fudge,
															width: percentView.width + 2*fudge,
															height: percentView.height + 2*fudge,
														};

														var inside = coords.x >= percentView.x
															&& coords.y >= percentView.y
															&& coords.x + coords.width <= percentView.width + percentView.x
															&& coords.y + coords.height <= percentView.height + percentView.y
														return inside;
	},


	_modalSelectEntityCategory	: function(catId) {

															// ensure submenus are exactly same height as cat menu
															$('.entity-submenus ul').css('height', $('.entity-categories').innerHeight());

															if($('.entity-categories li.selected').attr('id') == catId) return;
															console.log('switching to obj: %o', $('.entity-categories li.selected'));
															$('.entity-submenu li').removeClass('selected');

															this.element.find('.entity-categories li').removeClass('selected');
															this.element.find('.entity-categories li#' + catId).addClass('selected');

															this.element.find('.entity-submenu').removeClass('selected');
															this.element.find('#entity-submenu-' + catId).addClass('selected');

															this.element.find('#entity-submenu-' + catId + ' li:first-child').trigger('click');
	},

	_modalSelectEntity 				: function(entityId) {

															this.transcribeModal.find('div.transcribe-entity-fieldsets .save-button').show();

															$('.entity-submenu li').removeClass('selected');
															$('#entity-' + entityId).addClass('selected');
		
															this.currentEntityId = entityId;
															var entity = this._entityById(this.currentEntityId);

															// Hide entity type selector
															this.transcribeModal.find('ul.entity-types').hide();
															// Hide all fieldsets
															this.transcribeModal.find('.transcribe-entity-fieldset').hide();


															// Set title to entity name
															this.transcribeModal.find('h1.transcribe-modal-title').text(entity.name);
															if(entity.description) {
																this.transcribeModal.find('h1.transcribe-modal-title').append($('<span></span>').text(entity.description));
															}
												
															// Show form
															this.transcribeModal.find('#transcribe_fieldset_' + this.currentEntityId).show();

															// Select first (with delay to ensure trigger isn't clobbered by other click events)
															setTimeout((function() {
																this.transcribeModal.find('#transcribe_fieldset_' + this.currentEntityId).find('input').first().focus();
															}).bind(this), 1);

															this.transcribeModal.find('div.transcribe-entity-fieldsets').show();
	},

	_normalizeBounds      	: function(bounds) {
														var zoomLevel = this.options.zoomLevel;
														var assetWidth = this.assets[this.assetIndex].displayWidth;
														var assetHeight = this.assets[this.assetIndex].displayHeight;
														var normalized_bounds = {width: bounds.width / assetWidth,
																										 height: bounds.height / assetHeight,
																										 x : bounds.x / assetWidth,
																										 y : bounds.y / assetHeight,
																										 zoom_level:zoomLevel };
														return normalized_bounds
	},

	_showBox               	: function(position) {


														// Reset:
														this.transcribeModal.find('ul.entity-types').show();
														this.currentEntityId = null;
															
														$('.transcribe-modal-containment').show();
														// $('.transcribe-modal').draggable( "option", "containment", "#" );

														var doc_height = $(document).height();
														$('.darkening-overlay').show()
															.css('height',doc_height)

														this.assets[this.assetIndex].element.imgAreaSelect({disable:true});



														if(position){
															if(position.width && position.height){
																var zoomLevel = this.options.zoomLevel;

																this.options.zoomBoxWidth = position.width * zoomLevel;
																this.options.zoomBoxHeight = position.height * zoomLevel;
																
																this.transcribeModal.zoomBox
																	.setSize( position.width * zoomLevel, position.height * zoomLevel);

																this.transcribeModal.zoomBox
																	.css("top", this.options.annotationBoxHeight+1)
																	.css("left",this.options.annotationBoxWidth/2.0-this.options.zoomBoxWidth/2.0);
																
															}
															var xOffset = $(this.transcribeModal).width()/2.0;
															var yOffset = $(this.transcribeModal).height()+($(this.transcribeModal.zoomBox).height())/2.0;
															// var screenX = position.x-xOffset;
															this.transcribeModal.css("top",position.y-yOffset);
															console.log('setting zoom box pos: %o, %o', position.x, position.y);
															// this.transcribeModal.css("position","absolute");
															var zoomX = -1*(position.x*this.options.zoomLevel-this.options.zoomBoxWidth/2.0);
															var zoomY = -1*(position.y*this.options.zoomLevel-this.options.zoomBoxHeight/2.0);
															
															if(position.y > this.options.assetScreenHeight/2){
																this.options.orientation="floatAbove";
																$(".transcribe-form-holder").css("top",0);
															}
															else{
																this.options.orientation="floatUnder";
																$(".transcribe-form-holder").css({
																	top: this.options.annotationBoxHeight - 60,
																	height: this.options.annotationBoxHeight + this.options.zoomBoxHeight + 60
																});
																$(".transcribe-form-top-bar").css("padding-top", this.options.zoomBoxHeight + 80);
															}
															
															
															$(this.transcribeModal.zoomBox).find("#transcribe-zoom-box-image-holder").css({
																top: zoomY,
																left: zoomX
															});
														}

														this.transcribeModal.show();

														this._modalUpdateZoomControls();
	}, 

	_showBoxWithAnnotation  : function(annotation) {
														zoom = this.options.zoomLevel;
														
														var bounds = this._denormalizeBounds(annotation.bounds);
														
														bounds = {x: bounds.x+bounds.width/2,
																		 y: bounds.y+bounds.height/2,
																 		 width: bounds.width ,
																		height: bounds.height}
														console.log('showing box at %o, (%o)', bounds, annotation.bounds);
																			
														this._showBox(bounds);
														this._modalSelectEntity(annotation.entity_id);

														var inputs = this._currentInputs();
														inputs.each(function(index, el) {
															var field_key = $(el).data('field-key');
															$(el).val(annotation.data[field_key]);
														});

	},

	_switchEntityType       : function (event){
														alert('dep');
															// console.log("_switchEntityType.._selectEntity(" + event.data + ")");
															this._selectEntity(event.data);
														},
														
	_updateWithDrag 				: function(position){
														// console.log('_updateWithDrag: ', position);
														var x = position.left+ this.options.annotationBoxWidth/2;
														var y = position.top + this.options.annotationBoxHeight+ this.options.zoomBoxHeight/2.0;
														
														// this._checkAndSwitchOrientation({x:x,y:y});
														var zoomX = -1*(x*this.options.zoomLevel-this.options.zoomBoxWidth/2.0);
														var zoomY = -1*(y*this.options.zoomLevel-this.options.zoomBoxHeight/2.0);
													
														$(this.transcribeModal.zoomBox).find("img").parent().css("top", zoomY )
																															.css("left", zoomX);	

														this._highlightLinesInside();
	},

	_transcribeSelectedLines	: function() {
														// var bboxElem = this.lineBoundingBox;
														var coords = this._linesCoords(this.selectedLines);
														var position = this._denormalizeBounds(coords);
														console.log('selected lines pos: ', coords, position.x, position.y, position.width, position.height);
														position.x += position.width/2;
														position.y += position.height/2;
														
														this._showBox(position);
	},

	/* End: UI Utils */


	
	/* Begin: UI Generation */

	_createHocrElements			: function(asset) {

														asset.lines = [];

														var lineCount = 0;

														var display_height = asset.displayHeight;
														for(var i=0;i<asset.hocr_blocks.length;i++) {
															var b = asset.hocr_blocks[i];
															for(var j=0;j<b.pars.length;j++) {
																var lines = b.pars[j];

																for(var k=0;k<lines.length;k++) {
																	var _l = lines[k];
																	// Convert coords from w,h,ul form to width,height,x,y form
																	var l = {
																		coords: {
																			width: _l.coords.w,
																			height: _l.coords.h,
																			x: _l.coords.ul[0],
																			y: _l.coords.ul[1]
																		}
																	};
																	l.element = $('<div class="hocr-line"></div>')
																		.css({
																			left: l.coords.x * asset.displayWidth,
																			top: l.coords.y * asset.displayHeight,
																			width: l.coords.width * asset.displayWidth,
																			height: l.coords.height * asset.displayHeight
																		})
																		.click(this._hocrLineClicked.bind(this, l))
																		.dblclick(this._hocrLineDoubleClicked.bind(this, l))
																		.appendTo(this.element.find('.transcribe-image-holder'));
																	l.id = asset.uri + '-' + (++lineCount);

																	asset.lines.push(l);
																}
															}
														}
	},

 	_generateField          : function (field, entity) {
														var inputDiv = $("<div class='transcribe-field-row'></div>");
														var id = "transcribe-field-" + field.field_key;
														var label = $('<label for="' + id + '">' + field.name + "</label>");
														inputDiv.append(label)
														switch(field.kind){
															case("text"):
																result=$("<input>");
																result.attr("type",'text');

																if(field.vocab) {
																	var source = null;
																	if($.isArray(field.vocab)) {
																		source = field.vocab;

																	} else if(field.vocab == 'suggest-common') {
																		source = '/transcriptions/terms/' + entity.id + '/' + field.field_key;
																	}

																	if(source)
																		result.autocomplete({source: source});
																}

																
																if (field.options.text){
																	if(field.options.text.max_length){
																		result.attr("size",field.options.text.max_length);
																	}
																}
																break;
															case("select"):
															  var result = $("<select>");
																result.attr("kind",'select');
															  $.each(field.options.select, function(){
																	result.append("<option value='"+this+"'>"+this+"</option>");
																});
																
																break;
															case("date"):
																result=$("<input>");
																result.attr("type","text");
																result.attr('placeholder', 'MM/DD/YYYY');
																break;
													 }
													 result.data('field-key', field.field_key);
													 return inputDiv.append(result);
	},
	

	_generateInputs 			: function(entities){
													 var inputBar = $('<div class="transcribe-entity-fieldsets"></div>');
													 var self = this;
													 
													 $.each(entities, function(entity_index,entity){
															var currentInputPane = $('<div class="transcribe-entity-fieldset"></div>')
																.attr('id', 'transcribe_fieldset_' + entity.id)
																.hide();

															var help = $('<div class="transcribe-form-help"></div>').text(entity.help ? ('Hint: ' + entity.help) : '');
															if(entity.examples) {
																var examples = $('<ul></ul>');
																for(var i=0;i<entity.examples.length;i++) {
																	var ex = entity.examples[i];
																	if($.type(ex) == 'array') {
																		text = ex.join(',&nbsp;&nbsp;&nbsp;');
																	} else {
																		text = ex;
																	}
																	examples.append($('<li>' + text + '</li>'));
																}
																help.append($('<h2>Examples</h2>')).append(examples);
															}

															if(entity.extended_help) {
																help.append($('<a href="javascript:void(0);">More help...</a>')
																	.click(self.showHelp.bind(self, entity.id))
																);
															}
															currentInputPane.append(help);


															$.each(entity.fields, function(field_index,field){
																var current_field = self._generateField(field, entity);
																currentInputPane.append(current_field);
																// console.log('appended %o to %o', current_field.css('display'), inputBar);
															});

															inputBar.append(currentInputPane);

													 });
													return inputBar;
	},

	_generateMarker 				: function (position, marker_id){
														var marker = $('<div><div class="transcribe-color-overlay"></div></div>')
																						.addClass('transcribe-marker')
																						.css({
																							width: position.width,
																							height: position.height,
																							top: position.y,
																							left: position.x
																						})
																						.dblclick(this.editAnnotation.bind(this, marker_id));
														var controls = $("<div class='transcribe-marker-controls'></div>");
														
														controls.append($('<a href="javascript:void(0);">Edit</a>').click(this.editAnnotation.bind(this, marker_id)));
														controls.append($('<a href="javascript:void(0);">Delete</a>').click(this.deleteAnnotation.bind(this, marker_id)));
														marker.append(controls);
														this.element.find('.transcribe-image-holder').append(marker);
														return marker;
	},
		
	_generateTranscribeModal : function() {
														var self = this;
														var image = this.imageElements[this.assetIndex];
														var imageLoc = image.offset();

														var totalHeight = this.options.zoomBoxHeight/2+ this.options.annotationBoxHeight;

														var containmentWidth = this.assets[this.assetIndex].displayWidth * this.options.zoomLevel
														var containmentHeight = this.assets[this.assetIndex].displayHeight * this.options.zoomLevel
														var modalContainment = $('<div class="transcribe-modal-containment"></div>').css({
															width: containmentWidth,
															height: containmentHeight,
															left: -1 * (containmentWidth - this.assets[this.assetIndex].displayWidth) / 2,
															top: -1 * this.options.annotationBoxHeight
														});
														this.element.find('.transcribe-image-holder').append(modalContainment);

														var containment = modalContainment;


														var modal = $("<div class='transcribe-modal'></div>").draggable(this, { containment: containment, cursor:false, drag: function(event,ui){
															self._updateWithDrag(ui.position);
														}});
														

														var overlay = $('<div class="darkening-overlay"></div>')
															.click(this._dismissAnnotationBox.bind(this));
														$(document.body).append(overlay);

														var closeButton = $('<a href="#" class="transcribe-modal-close-button"><span class="ui-icon ui-icon-circle-close"></span></a>');
														closeButton.click(function(event){
															event.stopPropagation();
															event.preventDefault();
															self._dismissAnnotationBox();
														});

														var topBar 				= $('<div class="transcribe-form-top-bar"></div>');
														topBar.append(closeButton);

														topBar.append($('<h1 class="transcribe-modal-title">' + this.options.modalDefaultTitle + '</h1>'));


														var categoryChoices = $('<ul class="entity-categories"></ul>');
														var entitySubmenus = $('<div class="entity-submenus"></div>');
														for(var i=0;i<this.options.template.entities.length;i++) {
															var entity = this.options.template.entities[i];
															var catName = entity.category;
															var catId = 'category-' + catName.replace(/ /,'_').toLowerCase();
															if($(categoryChoices.find('#' + catId)).length == 0) {
																categoryChoices.append(
																	$('<li id="' + catId + '">' + catName + '</li>')
																		.css('background-image','url(/assets/' + catId + '.png)')
																		.click(this._modalSelectEntityCategory.bind(this, catId))
																);
																entitySubmenus.append($('<ul class="entity-submenu" id="entity-submenu-' + catId + '"></>'));
															}
															entitySubmenus.find('#entity-submenu-' + catId).append(
																$('<li id="entity-' + entity.id + '">' + entity.name + '</li>')
																	.click(this._modalSelectEntity.bind(this, entity.id))
															);
														}

														var form = $('<div class="transcribe-form"></div>');
														form.append(categoryChoices);
														form.append(entitySubmenus);

														var inputBar      = this._generateInputs(this.options.template.entities);
														inputBar.append($("<input type='submit' value='add'>").css('display','none').addClass("save-button").click(function(e){ self._addAnnotation(e) } ));
														inputBar.append($('<span class="modal-status-message"></span>'));
														form.append(inputBar);
														
														modal.transcriptionArea = $('<div class="transcribe-form-holder"></div>');
														modal.transcriptionArea.append(topBar);
														modal.transcriptionArea.append(form);

														modal.append(modal.transcriptionArea);


														modal.transcriptionArea.css("width",this.options.annotationBoxWidth+"px")
																				 .css("height",this.options.annotationBoxHeight+"px");
														modal.css("width",this.options.annotationBoxWidth+"px")
																										 .css("height",this.options.annotationBoxHeight+"px");

														modal.zoomBoxMoved = (function(ui) {
															({
																top: ui.size.height
															});
														}).bind(modal);
														
														modal.zoomBox = this._generateZoomBox();
														modal.append(modal.zoomBox);
														modal.css("z-index","100");
														return modal;
														
	},

	_generateZoomBox				: function(){
														var image_holder = $('<div id="transcribe-zoom-box-image-holder"><img></img></div>')
																												.css('position','absolute')
																												.css('top',0)
																												.css('left',0);

														var zoomBoxHolder = $('<div id="transcribe-zoom-box-holder"><div id="transcribe-zoom-box"></div></div>')
															.css("top", this.options.annotationBoxHeight)
															.css("left",this.options.annotationBoxWidth/2.0-this.options.zoomBoxWidth/2.0);

														var boxControls = $('<div class="zoom-box-controls"></div>');

														boxControls.append($('<div class="zoom-box-control button-next-line"><span class="ui-icon ui-icon-arrowthickstop-1-s"></span>Next Line</div>').click(this._modalMoveToLine.bind(this, 1)));
														boxControls.append($('<div class="zoom-box-control button-previous-line"><span class="ui-icon ui-icon-arrowthickstop-1-n"></span>Previous Line</div>').click(this._modalMoveToLine.bind(this, -1)));
														zoomBoxHolder.append($('<div class="zoom-box-control button-add-next-line"><span class="ui-icon ui-icon-plusthick"></span>Add Next Line</div>').css({position:'absolute',width:100,right:0,bottom:-25}).click(this._modalAddLine.bind(this, 1)));
														zoomBoxHolder.append(boxControls);

														zoomBoxHolder.setSize = (function(w, h) {
															var elems = [this, this.find('#transcribe-zoom-box')];
															$.each(elems, function(i, el) {
																el.css({
																	width: w,
																	height: h
																});
															});
														}).bind(zoomBoxHolder);

														zoomBoxHolder.find('#transcribe-zoom-box')
															.append(image_holder);

														zoomBoxHolder.resizable({
															// handles: "ne, e, se, s, sw, w, nw, n",
															handles: "e, se, s",
															alsoResize: '#transcribe-zoom-box',

															resize: (function(e, ui) {
																this.options.zoomBoxHeight = ui.size.height;
																this.options.zoomBoxWidth = ui.size.width;

																$(".transcribe-form-holder .transcribe-form-top-bar")
																	.css("padding-top", this.options.zoomBoxHeight+80);
																$(".transcribe-form-holder")
																	.css("height", this.options.annotationBoxHeight + this.options.zoomBoxHeight + 80);
															}).bind(this)
														});

														// Create zoomed hocr line elems
														for(var i=0;i<this.assets.length;i++) {
															var asset = this.assets[i];
															for(var j=0;j<this.assets[i].lines.length;j++) {
																var l = this.assets[i].lines[j];

																l.zoomElement = $('<div class="hocr-line hocr-zoomed-line"></div>')
																	.css({
																		left: l.coords.x * asset.displayWidth * this.options.zoomLevel,
																		top: l.coords.y * asset.displayHeight * this.options.zoomLevel,
																		width: l.coords.width * asset.displayWidth * this.options.zoomLevel,
																		height: l.coords.height * asset.displayHeight * this.options.zoomLevel
																	})
																	.appendTo(image_holder);

															}
														}
														return zoomBoxHolder;
		
	},

	/* End: UI Generation*/



	/* Begin: Data Utils */

	_addAnnotation          : function (event){
														this.imageElements[this.assetIndex].imgAreaSelect({disable:false});
														
														event.preventDefault();
														event.stopPropagation();
												   	
														var location = this._currentCoords();
														location.zoom_level = this.options.zoomLevel;
																																											
														var annotation_data = this._serializeCurrentForm();
														annotation_data.bounds = this._normalizeBounds(location);
														annotation_data.asset_index = this.assetIndex;
														annotation_data.asset_id = this.assets[this.assetIndex].id;
													
														if (this.editing_id!=null){
															if(this.annotations[this.editing_id].marker_element)
																this.annotations[this.editing_id].marker_element.remove();
															annotation_data.id = this.editing_id;
															
															this.annotations[this.editing_id] = annotation_data;
															this.annotations[this.editing_id].marker_element = this._generateMarker(location, this.editing_id);
															console.log('created new marker: ', this.annotations[annotation_data.id]);
															if (this.options.onAnnotationUpdated!=null) {
														 		this.options.onAnnotationUpdated.call(this, annotation_data);
															}
															this.editing_id=null;
														}
														else{
															
															annotation_data.id = this.annIdCounter++;

															this.annotations[annotation_data.id] = annotation_data;
															this.annotations[annotation_data.id].marker_element = this._generateMarker(location, annotation_data.id);
															
													  	if (this.options.onAnnotationAdded!=null){
														 		this.options.onAnnotationAdded.call(this, annotation_data);
															}
														}

														$('.modal-status-message').text('Field added');
														setTimeout(function() { $('.modal-status-message').fadeOut(); }, 2000);
														
														// this._dismissAnnotationBox();
														this._modalMoveToLine(1);
														this.transcribeModal.find('div.transcribe-entity-fieldsets input[type=text]').val('');
	},


	_entityById							: function(id) {
														for(var i=0;i<this.options.template.entities.length;i++) {
															var entity = this.options.template.entities[i];
															if(entity.id == id) 
																return entity;
														}
	},

	_entityByName						: function(name){
														for(var i in this.options.template.entities ){
																if (this.options.template.entities[i].name == name)
																	return this.options.template.entities[i];
														}
	},

	_serializeCurrentForm   : function(){	
														var inputs = this._currentInputs();
													
														var entity = this._entityById(this.currentEntityId);
														var result = {entity_name: entity.name, data:{}, entity_id: this.currentEntityId};
														inputs.each(function() {
															var field_id = $(this).data('field-key');
															result.data[field_id] = $(this).val();
														});
														return result;
	},

	_saveSucceeded					: function (){
														console.log('succeeded');
														if (this.options.onSaveSuccess){
															this.options.onSaveSuccess.apply(this);
														}
	},

	_saveFailed  						: function (){
														console.log('failed');
														if (this.options.onSaveFail){
															this.options.onSaveFail.apply(this);
														}
  },

	/* End: Data Utils */
									

});
	
