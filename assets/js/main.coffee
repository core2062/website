# this points to the server that's holding all our content in wordpress
BACKEND_URL = 'http://69.55.49.53'

# PhantomJS doesn't support bind yet
`Function.prototype.bind = Function.prototype.bind || function (thisp) {
	var fn = this;
	return function () {
		return fn.apply(thisp, arguments);
	};
};`

window.$ = require 'jquery'
_ = require 'underscore'
Backbone = require 'backbone'
gallery = require './gallery'
jsonp = require 'jsonp'

# these only need to be called... no init
require './flying-focus'
require './jquery.fancybox'
require './jquery.form'
require './contact-form'

$('.menu li:not(:has(ul))').addClass 'no-children'

require './jquery.slicebox'
$('.sb-slider').slicebox(
	orientation: 'r'
	cuboidsRandom: true
	autoplay: true
	sequentialFactor: 200
)

require './jquery.hypher'
$('p').hyphenate 'en-us'

### Twitter Broke its API
require './jquery.tweet'
jQuery(function($){
	$("#twitter_box div").tweet({
		username: "core2062",
		count: 5,
		loading_text: "loading tweets..."
	});
});
###

window._wpcf7 =
	loaderUrl: BACKEND_URL + '/wp-content/plugins/contact-form-7/images/ajax-loader.gif',
	sending: "Sending ..."

p = (args...) ->
	console.log args...

#general functions
String::title_case = ->
	@replace /\w\S*/g, (txt) ->
		txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()

###*
 * modify the navbar to highlight the correct current page.
 * this view just manages the navbar at the top of the page
###
class NavView extends Backbone.View
	el: $('nav')[0] # element already exists in markup

	render: ->
		page = @model.current_page()

		# set the title of the page
		document.title = "#{page.get('name')} | Chaz Southard"

		# ensure that the correct navbar button is selected... since it is
		# a radio button, it unselects anything else
		@$el.find("\##{page.get('slug')}_nav").prop "checked", true
		@$el.find('select').val('#' + page.get('slug'))

		p "(nav) page: #{page.get('name')}"

	added_page: (page_model) ->
		name = page_model.get('name')
		slug = page_model.get('slug')

		@$el.find('.buttonset').append("""
			<input type="radio" name="nav" value="#{slug}", id="#{slug}_nav")>
			<label for="#{slug}_nav">
				<a href="#!#{slug}">#{name}</a>
			</label>
		""")

		@$el.find('select').append("""
			<option value="##{slug}">#{name}</option>
		""")

	initialize: ->
		_.bindAll @
		@model.on('change:selected', @render)
		@model.on('add', @added_page)


# the router makes the backbuttons work (since we're not really going to
# another page, we are just loading new content for the page we are on). also
# it deals with firing events when the url hash is changed
class Router extends Backbone.Router
	# forward changes in the route to the navigation view
	routes:
		"*page": "change_page"

	change_page: (page) ->
		if page? and page[0] is '!' then page = page[1..]
		if page isnt "" then @model.change_page(page)

	initialize: (options) ->
		# assign a model during init like in a view
		@model = options.model

# this is a model that represents a single page... it's basically just used to
# hold the slug, name, and if it is selected or not
class Page extends Backbone.Model
	defaults:
		name: ''
		slug: ''
		selected: false # value used by Pages for changing the active page
		categories: []

		# bind-able functions... empty by default
		first_load: (->)
		on_load: (->)
		on_unload: (->)

	# represents a page in the application
	sync: ->
		false # changes to Pages don't get stored anywhere

	onchange: ->
		if @get('selected')
			@get('on_load').call()
		else
			@get('on_unload').call()

	initialize: ->
		_.bindAll @
		@on('change:selected', @onchange)

		# for page specific init functions
		@get('first_load').call()

# this is a view that's connected to the page model... it just deals with
# hiding the content of pages that we are not on, and showing the content of
# the page that we are on
class PageView extends Backbone.View
	render: ->
		if @model.get('selected')
			@el.style.display = 'block' # show
		else
			@el.style.display = 'none' # hide

	initialize: ->
		_.bindAll @

		@model.on('change:selected', @render)
		@model.view = @

		slug = @model.get('slug')

		classes = @model.get('categories').join(' ')
		$(window.navView.el).after("""
			<section id="#{slug}_content" class="#{classes}">
			</section>
		""")

		@el = $("\##{slug}_content")[0]
		@render()

# this is a collection of all the pages in the application... it deals with
# changing the current page when the url changes
class PagesCollection extends Backbone.Collection
	# to determine what should be rendered in the navbar on any given page
	model: Page
	default_page: 'blog'

	added_page: (page_model) ->
		#used to create the view for a page after it has been added
		new PageView({model: page_model})

	change_page: (page_slug) ->
		# update the active page. this should only be called by the router
		page = @find(
			(page_obj) ->
				return page_obj.get('slug') is page_slug
		)

		try
			# deselect the current page (if it's set)
			@current_page().set(selected: false)

		if page?
			page.set(selected: true)
		else
			p "#{page_slug} doesn't exist, redirecting to #{@default_page}..."

			router.navigate('!' + @default_page,
				trigger: true
				replace: true
			)

	###*
	 * @return Page the model of the active page
	###
	current_page: ->
		return @where(selected: true)[0]

	initialize: ->
		_.bindAll @
		@on("add", @added_page)

#create all the models & views in the application
window.pages = new PagesCollection()
window.router = new Router model: pages
window.navView = new NavView model: pages

###*
 * holds all the attachments that we find when adding pages. later used to add
   captions and titles n' stuff to the images because a lot of that isn't
   avaliable in the outputted html
 * all the keys are urls, so it's easy to lookup based on the images
 * @type {Object}
###
window.attachment_index = {}

###*
 * put `attachments` into the `attachment_index`
 * @param {[type]} attachments an array of attachments
 * @return {[type]} [description]
###
process_attachments = (attachments) ->
	for attachment in attachments
		url = attachment['url']
		delete attachment['url']
		attachment_index[url] = attachment


num_pages_loaded = 0
total_pages = 2 # not really pages: just number of requests
pages_loaded = ->
	# make sure everything is loaded first
	num_pages_loaded++
	if num_pages_loaded isnt total_pages
		return

	$('#loading').remove()

	Backbone.history.start()
	
	# change to default page at startup (if there is no hash fragment)
	if Backbone.history.fragment is ''
		App.Router.navigate('!' + pages.default_page,
			trigger: true
			replace: true
		)

	gallery() # basically parse the gallery, and spit it back out

	$('.gallery a').fancybox(
		nextEffect: 'fade'
		prevEffect: 'fade'
		padding: 0
		margin: [15, 15, 40, 15]
		afterLoad: ->
			list = $("#links")
			
			if not list.length
				list = $('<ul id="links">')
			
				for i in [0...@group.length]
					$("<li data-index=\"#{i}\"><label></label></li>").click(->
						$.fancybox.jumpto( $(@).data('index'))
					).appendTo(list)
				list.appendTo('body')

			list.find('li').removeClass('active').eq( this.index ).addClass('active')
		beforeClose: ->
			$("#links").remove()
	)

	#make the contact form work
	form = $('.wpcf7 form')[0]
	$(form).attr('action', BACKEND_URL + $(form).attr('action'))
	$.wpcf7Init()

	p 'all loaded'
	window.prerenderReady = true

jsonp("#{BACKEND_URL}/?json=get_page_index", {}, (err, data) ->
	# loop through the pages
	for page in data['pages']
		process_attachments(page['attachments'])

		categories = []
		for category in page['categories']
			categories.push 'category-' + category['slug']

		pages.create(
			slug: page['slug']
			name: page['title']
			categories: categories
		)

		# add the content
		$("##{page['slug']}_content")[0].innerHTML = page['content']
		p "loaded page: #{page['title']}"

	pages_loaded()
)

pages.create(
	slug: 'blog'
	name: 'Blog'
)

# get all the content on the homepage as JSON and then call the function
# with the data
jsonp("#{BACKEND_URL}/?json=1", {}, (err, data) ->
	# loop through the data and make a section for each post, and append it to the blog page
	for post in data['posts'] 
		process_attachments(post['attachments'])

		$('#blog_content').append("""
		<section>
			<h1 class="title">#{post['title']}</h1>
			<p class="post-info">Posted on <span class="date">#{post['date']}</span> by <span class="author">#{post['author']['name']}</span></p>
			#{post['content']}
		</section>
		""")
	
	p "loaded page: Blog"
	pages_loaded()
)

$("nav select").change( ->
	window.location = $(@).find("option:selected").val();
)
