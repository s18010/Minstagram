// メニューバー固定
/*
let _window = $(window),
    _header = $('.menu'),
    headerBottom;

_window.on('scroll',function(){
    headerBottom = $('header').height();
    if(_window.scrollTop() > headerBottom){
        _header.addClass('fixed');
    }
    else{
        _header.removeClass('fixed');
    }
});

_window.trigger('scroll');
*/

// shards()
$(function() {
  $('#bg').shards(
    [255,220,205,.15],
  	[255,245,241,.15],
  	[255,255,255,.25],
  	100,
  	.58,
  	2,
  	.15,
  	true);
});

// featured_contentを一定時間ごとに切り替え
$(function(){
    let setImg = '#photo';
    let fadeSpeed = 1600;
    let switchDelay = 1000;

    $(setImg).children('img').css({opacity:'0'});
    $(setImg + ' img:first').stop().animate({opacity:'1',zIndex:'0'},　fadeSpeed);

    setInterval(function(){
        $(setImg + ' :first-child').animate({opacity:'0'},fadeSpeed).next('img').animate({opacity:'1'},fadeSpeed).end().appendTo(setImg);
    },switchDelay);
});
