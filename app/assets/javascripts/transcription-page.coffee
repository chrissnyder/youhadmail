$ ->
  calculatedHeight = $(document).height() - $('#header').outerHeight()
  $('.leftBar').height calculatedHeight

  $('.rightBar').width $(document).width() - $('.leftBar').outerWidth()