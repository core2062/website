$ = require 'jquery'
_ = require 'underscore'
Backbone = require 'backbone'

###*
 * A quick and simple UUID function. Credit to
   https://gist.github.com/jed/982883
 * @return {String} A random string
###
uuid = (a) ->
  `a?(a^Math.random()*16>>a/4).toString(16):([1e7]+1e3+4e3+8e3+1e11).replace(/[018]/g,uuid)`

# get the libraries and then call the function

# this is a model that represents a single photo... it's basically just used to hold the slug, name, and if it is selected or not
class Photo extends Backbone.Model
	defaults:
		title: ''
		url: ''
		thumb_url: ''
		caption: ''
		slug: ''
		group_id: ''
		description: ''

	sync: ->
		false # changes to Photos don't get stored anywhere

	initialize: ->
		#_.bindAll @

class PhotoView extends Backbone.View
	tagName: 'figure'
	render: ->
		@el.innerHTML = """
		<a class="fancybox" rel="#{@model.get('group_id')}" href="#{@model.get('url')}" title="#{@model.get('title')}">
			<img src="#{@model.get('thumb_url')}" alt="" />
			<figcaption>#{@model.get('title')}</figcaption>
		</a>
		"""

	initialize: ->
		#_.bindAll @
		@model.view = @
		@render()

class GalleryView extends Backbone.View
	className: 'gallery'
	initialize: ->
		#_.bindAll @

class Gallery extends Backbone.Collection
	model: Photo

	added_photo: (photo_model) ->
		#used to create the view for a photo after it has been added
		photo_model.set('group_id', @group_id)
		@view.$el.append(new PhotoView(model: photo_model).el)

	initialize: ->
		#_.bindAll @
		@group_id = uuid()
		@on("add", @added_photo)
		@view = new GalleryView model: @

# process_galleries
module.exports = () ->
	gallery = []
	$('.gallery').each((i, element) ->
		gallery[i] = new Gallery()
		$(element).find('a').each((e) ->
			url = $(@).attr('href')
			img = attachment_index[url]
			gallery[i].add(
				title: img['title']
				url: url
				thumb_url: img['images']['thumbnail']['url']
				caption: img['caption']
				description: img['description']
				slug: img['slug']
			)
		).promise().done( ->
			$(element).replaceWith(gallery[i].view.el)
		)
	)
