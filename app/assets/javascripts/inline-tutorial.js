
var InlineTutorial = function(steps) {

	this.steps = steps;
	this.stepIndex = 0;

	this.element = $('<div class="inline-tutorial-holder"></div>')
		.append($('<div class="inline-tutorial-box"><h1>Tutorial</h1><div class="tutorial-content"></div><div class="tutorial-controls"></div></div>'))
		.append($('<div class="inline-tutorial-arrow"></div>'));

	this.element.find('.tutorial-controls').append(this.doneButton = $('<span>done</span>').click(this.stop.bind(this)));
	this.element.find('.tutorial-controls').append(this.nextButton = $('<span>next</span>').click(this.next.bind(this)));
	this.element.find('.tutorial-controls').append(this.previousButton = $('<span>previous</span>').click(this.previous.bind(this)));
	// this.element.append($('<span class="ui-icon ui-icon-circle-close"></span>').click(this.stop.bind(this)));

	this.element.draggable({
		start: this._setArrow.bind(this, false)
	});

	$(document.body).append(this.element);

};

InlineTutorial.prototype = {

	next							: function() {
											this._advance(1);
	},
	
	previous					: function() {
											this._advance(-1);
	},

	start							: function() {
											this.stepIndex = 0;
											this.element.show();

											this._setArrow(this.steps[this.stepIndex].arrow);

											var coords = this._boxCoords(this.stepIndex);
											this.element.css({
												left: coords.left,
												top: coords.top
											});
											this._updateControls();

											var step = this.steps[this.stepIndex];
											this._setContent(step.content, step.title, true);

	},
	
	stop							: function() {
											this.element.hide();
	},

		
	
	_advance					: function(count) {

											var previousCoords = this.element.offset();

											this.stepIndex += count;

											// Hide arrow
											this.element.find('.inline-tutorial-arrow')
												.attr('class','inline-tutorial-arrow')
												.hide();

											var coords = this._boxCoords(this.stepIndex);
											var moved = previousCoords.left != coords.left || previousCoords.top != coords.top;

											// Create update-content call
											var updateContent = (function(step) {
												this._setContent(step.content, step.title, true);
												this._setArrow(step.arrow);
											}).bind(this, this.steps[this.stepIndex]);

											// Only run animation if coords changed
											if(moved) {
												this._setContent('', '', false);
												this.element.animate({
													left: coords.left,
													top: coords.top,
												}, null, null, updateContent);

											// Otherwise just run update-content call
											} else
												updateContent();

											this._updateControls();

											// for dbging
											// this._highlightTarget(this.stepIndex);
	},

	// For debugging
	_highlightTarget	: function(index) {
	
											var coords = this._stepCoords(this.stepIndex);
											var highlight = $('<div></div>')
												.css({
													left: coords.left-10,
													top: coords.top-10,
													width: 10,
													height: 10,
													position: 'absolute',
													border: 'solid blue 1px',
													borderRadius: '5px'

												})
												.appendTo(document.body);
										
	},

	_setArrow					: function(location) {
											if(!location) {
												this.element.find('.inline-tutorial-arrow').hide();
											} else {
												this.element.find('.inline-tutorial-arrow')
													.addClass('arrow-' + location)
													.show();
											}
	},

	_setContent			: function(body, title, animate) {
											this.element.find('.tutorial-content')
												.hide()
												.html('<p>' + body.replace(/\n/g,'</p><p>') + '</p>')

											if(animate)
												this.element.find('.tutorial-content').fadeIn({duration:200});
											else
												this.element.find('.tutorial-content').show();

											this.element.find('h1').text(title);
	},
	
	_updateControls		: function() {
											this.element.find('.tutorial-controls span').hide();

											if(this.stepIndex < this.steps.length-1)
												this.nextButton.show();
											if(this.stepIndex > 0)
												this.previousButton.show();
											// if(this.stepIndex == this.steps.length-1) 
												this.doneButton.show();


	},

	_stepCoords				: function(index) {

											var step = this.steps[index];
											var coords = $(step.target).offset();

											if($.isNumeric(step.offset.x))
												coords.left += step.offset.x;
											else if(step.offset.x == 'center')
												coords.left += $(step.target).outerWidth() / 2;
											else if(step.offset.x == 'right')
												coords.left += $(step.target).outerWidth();

											if($.isNumeric(step.offset.y))
												coords.top += step.offset.y;
											else if(step.offset.y == 'center')
												coords.top += $(step.target).outerHeight() / 2;
											else if(step.offset.y == 'bottom')
												coords.top += $(step.target).outerHeight();

											return coords;
	},

	_boxCoords				: function(index) {
											var coords = this._stepCoords(index);

											var step = this.steps[index];

											// Compute offset of the point of the arrow from the UL corner of the box
											var arrowOffset = {
												left: 0,
												top: 0
											};

											// Temporarily place arrow in DOM to compute relative position & dimensions
											var tempArrow = false;
											if(step.arrow)
												tempArrow = $('<div class="inline-tutorial-arrow"></div>').addClass('arrow-' + step.arrow).appendTo(document.body);

											// No arrow? center box on target
											if(!step.arrow) {
												arrowOffset.left = this.element.outerWidth() / 2;
												arrowOffset.top = this.element.outerHeight() / 2;

											// Bottom / top: 
											} else if(step.arrow.match(/(bottom|top)-/)) {
												if(step.arrow.match(/bottom-/))
													arrowOffset.top = this.element.outerHeight() + tempArrow.outerHeight();
												else 
													arrowOffset.top = -1 * (tempArrow.outerHeight() - parseInt(this.element.css('borderTopWidth')));

												if(step.arrow.match(/(bottom|top)-right/))
													arrowOffset.left = this.element.outerWidth() - parseInt(tempArrow.css('right')) - tempArrow.outerWidth()/2;

												else if(step.arrow.match(/(bottom|top)-left/))
													arrowOffset.left = parseInt(tempArrow.css('left')) + tempArrow.outerWidth()/2 + parseInt(this.element.css('borderLeftWidth'));

											// Right / left:
											} else if(['right','left'].indexOf(step.arrow) >= 0) {
												arrowOffset.top = tempArrow.outerHeight()/2 + tempArrow.position().top + parseInt(this.element.css('borderTopWidth'));

												if(step.arrow == 'right') 
													arrowOffset.left = this.element.outerWidth() + tempArrow.outerWidth();
												
												else
													arrowOffset.left = -1 * (tempArrow.outerWidth() - parseInt(this.element.css('borderLeftWidth')));
											}

											if(tempArrow)
												tempArrow.remove();
											
											coords.left -= arrowOffset.left;
											coords.top -= arrowOffset.top;

											return coords;
	}
};
