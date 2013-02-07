
jQuery.fn.center = function () {
		if(['absolute','fixed'].indexOf(this.css('position')) < 0)
			this.css("position","absolute");
		
		var top = Math.max(0, ($(window).height() - $(this).outerHeight()) / 2);
		if(this.css('position') == 'absolute')
			top += $(window).scrollTop();
    this.css("top", top + 'px');
    this.css("left", Math.max(0, (($(window).width() - $(this).outerWidth()) / 2) + 
                                                $(window).scrollLeft()) + "px");
    return this;
}
