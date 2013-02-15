$(document).ready(function(){


var DEGREE_VARIANCE = 3;
var PIXEL_VARIANCE = {x: 20, y: 10};

var stacks = $(".photo-stack");
stacks.each(function() {
	$this = $(this);
	$imgs = $this.find('img');
	$imgCount = $imgs.length;
	$curr_index = 0;
	$imgs.first().addClass('current'); /* Set the image at top of stack to current */

	$this.delegate('img', 'click', function() {
			$this = $(this);

			/* If the image is at the top of the stack */
			if ($this.hasClass('current')) {
				/* Work out new z-index value */
				$zi = $this.css('zIndex') - $imgCount;

				/* Trigger animation */
				$this.addClass('animate');

				/* Assign new z-index value then stop animation after complete */
				setTimeout(function() { $this.css('zIndex', $zi); }, 200);
				setTimeout(function() { $this.removeClass('animate'); }, 1000);

				/* Set next image to current */
				$this.removeClass('current');
				if ($this.index() == 0) {
					$imgs.last().addClass('current');
				} else {
					$imgs.eq($this.index()-1).addClass('current');
				}
			}
		})

	$imgs.each(function() {
		$(this).css({
			top: 10+Math.round(Math.random() * PIXEL_VARIANCE.x), 
			left: 10+Math.round(Math.random() * PIXEL_VARIANCE.y)
		});
		var degree = Math.round(Math.random() * DEGREE_VARIANCE);
		var direction = Math.random() > 0.5? '' : 'neg';
		$(this).addClass('deg' + degree + direction);
	});
});

});
