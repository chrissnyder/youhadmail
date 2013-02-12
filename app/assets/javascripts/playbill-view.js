
var PlaybillView = function(elem_id, template) {

	this.element = $(elem_id).append($('<ul></ul>'));
	this.template = template;
	this.editor = null;

	this.containers = {};

	this.element.find('p, li, img, div')
		.attr('unselectable', 'on')
		.css('user-select', 'none')
		.on('selectstart', false);

	// var entityIds = ['Show_Title', 'Theatre_Name','Location','Show_Date','Cast_Member','Production_Staff','Advertisement'];
	for(var i=0;i<this.template.entities.length;i++) {
		var entity = this.template.entities[i];

		// var label = ids[i].replace(/_/,' ');
		var label = entity.name;
		if(['Cast Member','Advertisement'].indexOf(label) >= 0)
			label = label + 's';
		this.containers[entity.id] = $('<li></li>')
			.append($('<span class="entity-label">' + label + ':</span>'))
			.append($('<span class="placeholder"></span>')
				.append($('<a href="javascript:void(0);">Help</a>').click((function(entityId) {
					this.editor.showHelp(entityId);
				}).bind(this, entity.id)))
			)
			.appendTo(this.element.find('ul'));
	}

	$('.completed-playbill').show();

	this.entities = [];

}
PlaybillView.prototype = {
	
	addEntity:	function(entity) {

		$("#transcription-instructions").hide();
		$("#transcriptions-viewer").resizable({
			minWidth:200,
			minHeight:200,
			maxWidth:800,
			maxHeight:1200,
			alsoResize: '#transcriptions-viewer .completed-playbill'
		});

		this.entities.push(entity);

		entity.elem = this.elemByEntity(entity);
		entity.elem.setData(entity.data);
		entity.elem
			.prepend($('<a href="javascript:void(0);">Edit</a>')
				.click(this.editor.editAnnotation.bind(this.editor, entity.id))
			);

		if(this.containers[entity.entity_id].find('.placeholder').length == 1)
			this.containers[entity.entity_id].find('.placeholder').remove();

		if($(entity.elem).is('li')) {
			if(this.containers[entity.entity_id].find('ul').length == 0)
				this.containers[entity.entity_id].append($('<ul></ul>'));
			this.containers[entity.entity_id].find('ul').append(entity.elem);

		} else {	
			this.containers[entity.entity_id].append(entity.elem);
		}

		// console.log('added elem: %o to %o ' + entity.kind, entity.elem, this.containers[entity.kind]);
	},

	editEntity: function(entity) {
		// console.log('editing id ', entity.id, this.entities);
		for(var i=0;i<this.entities.length;i++) {
			if(this.entities[i].id == entity.id) {
				this.entities[i].elem.setData(entity.data);
				return;
			}
		}
		// console.log('couldnt find viewer to edit');
	},

	removeEntity: function(entity_id) {
		for(var i=0;i<this.entities.length;i++) {
			if(this.entities[i].id == entity_id) {
				this.entities[i].elem.remove();
			}
		}
	},

	elemByEntity: function(entity) {
		var elem;
		switch(entity.entity_name) {
			case 'Show Title':
				elem = $('<h1><span class="value-holder"></span></h1>');
				elem.setData = (function(data) { 
					this.find('.value-holder').text(data.title)
						.css('font-size', data.type=='official'?'20px':'15px'); 
				}).bind(elem);
				break;

			case 'Cast Member':
				elem = $('<li><span class="value-holder"></span></li>');
				elem.setData = (function(data) { this.find('.value-holder').text(data.character + (data.description?(', ' + data.description):'') + ': ' + data.actor); }).bind(elem);
				break;

			case 'Production Staff':
				elem = $('<li><span class="value-holder"></span></li>');
				elem.setData = (function(data) { this.find('.value-holder').text(data.role + ': ' + data.name); }).bind(elem);
				break;

			case 'Show Date':
				elem = $('<em><span class="value-holder"></span></em>');
				var viewer = this;
				elem.setData = (function(data) { this.find('.value-holder').html(viewer._formatDateRange(data.date_opened, data.date_closed)); }).bind(elem);
				break;

			default:
				elem = $('<li><span class="value-holder"></span></li>');
				elem.setData = (function(data) { 
					var s = '';
					for(var k in data) {
						s += (s?', ':'') + data[k];
					}
					this.find('.value-holder').text(s); 
				}).bind(elem);
		}
		var _id = entity.id;
		elem.click(this.editor.editAnnotation.bind(this.editor, _id));
		return elem;
	},

	_getEntity: function(type) {
		for(var i=0;i<this.template.entities.length;i++) {
			if(this.template.entities[i].name.replace(/ /,'_') == type) {
				return this.template.entities[i];
			}
		}
	},



	_formatDateRange: function(d1, d2) {
		var ret = this._formatDate(d1);
		if(d2 = this._formatDate(d2)) {
			ret += '&mdash;' + d2;
		}
		return ret;
	},

	_formatDate							: function(d) {
		try {
			var d = $.datepicker.parseDate('mm/dd/yy', d);
			return $.datepicker.formatDate('M d, yy', d);
		} catch(e) {
			return d;
		}
	}
};


