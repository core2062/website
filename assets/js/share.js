(function() {
  $.fn.share = function(opts) {
    var bubble, click_link, close, config, open, paths, set_opt, toggle,
      _this = this;
    $(this).hide();
    if (opts == null) {
      opts = {};
    }
    config = {};
    config.url = opts.url || window.location.href;
    config.text = opts.text || $('meta[name=description]').attr('content') || '';
    config.app_id = opts.app_id;
    config.title = opts.title;
    config.image = opts.image;
    config.button_color = '#333';
    config.button_background = '#e1e1e1';
    config.button_icon = 'export';
    config.button_text = 'Share';
    set_opt = function(base, ext) {
      if (opts[base]) {
        return opts[base][ext] || config[ext];
      } else {
        return config[ext];
      }
    };
    config.twitter_url = set_opt('twitter', 'url');
    config.twitter_text = set_opt('twitter', 'text');
    config.fb_url = set_opt('facebook', 'url');
    config.fb_title = set_opt('facebook', 'title');
    config.fb_caption = set_opt('facebook', 'caption');
    config.fb_text = set_opt('facebook', 'text');
    config.fb_image = set_opt('facebook', 'image');
    config.gplus_url = set_opt('gplus', 'url');
    config.selector = "." + ($(this).attr('class'));
    config.twitter_text = encodeURIComponent(config.twitter_text);
    if (typeof config.app_id === 'integer') {
      config.app_id = config.app_id.toString();
    }
    $(this).html("<label class='entypo-" + config.button_icon + "'><span>" + config.button_text + "</span></label><div class='social'><ul><li class='entypo-twitter' data-network='twitter'></li><li class='entypo-facebook' data-network='facebook'></li><li class='entypo-gplus' data-network='gplus'></li></ul></div>");
    if (!window.FB && config.app_id) {
      $('body').append("<div id='fb-root'></div><script>(function(a,b,c){var d,e=a.getElementsByTagName(b)[0];a.getElementById(c)||(d=a.createElement(b),d.id=c,d.src='//connect.facebook.net/en_US/all.js#xfbml=1&appId=" + config.app_id + "',e.parentNode.insertBefore(d,e))})(document,'script','facebook-jssdk');</script>");
    }
    paths = {
      twitter: "http://twitter.com/intent/tweet?text=" + config.twitter_text + "&url=" + config.twitter_url,
      facebook: "https://www.facebook.com/sharer/sharer.php?u=" + config.fb_url,
      gplus: "https://plus.google.com/share?url=" + config.gplus_url
    };
    bubble = $(this).parent().find('.social');
    toggle = function(e) {
      e.stopPropagation();
      return bubble.toggleClass('active');
    };
    open = function() {
      return bubble.addClass('active');
    };
    close = function() {
      return bubble.removeClass('active');
    };
    click_link = function() {
      var link;
      link = paths[$(this).data('network')];
      if (($(this).data('network') === 'facebook') && config.app_id) {
        window.FB.ui({
          method: 'feed',
          name: config.fb_title,
          link: config.fb_url,
          picture: config.fb_image,
          caption: config.fb_caption,
          description: config.fb_text
        });
      } else {
        window.open(link, 'targetWindow', 'toolbar=no,location=no,status=no,menubar=no,scrollbars=yes,resizable=yes,width=500,height=350');
      }
      return false;
    };
    $(this).find('label').on('click', toggle);
    $(this).find('li').on('click', click_link);
    $('body').on('click', function() {
      if (bubble.hasClass('active')) {
        return bubble.removeClass('active');
      }
    });
    setTimeout((function() {
      return $(_this).show();
    }), 250);
    return {
      toggle: toggle.bind(this),
      open: open.bind(this),
      close: close.bind(this),
      options: config,
      self: this
    };
  };

}).call(this);
