#TODO: rewrite with promises
jsonp = require 'jsonp'
Backbone = require 'backbone'
_ = require 'underscore'

class ContentObject extends Backbone.Model
  defaultFields: []

  ###*
   * Fields that are always ignored
   * @type {Array}
  ###
  ignoredFields: []
  
  ###*
   * Determine what fields we don't have (minus those that we are ignoring)
   * @return {Array} list of fields
  ###
  getMissingFields: ->
    _.difference @defaultFields, @ignoredFields, @keys()


class Post extends ContentObject
  defaultFields: [
    'id'
    'url'
    'type'
    'slug'
    'status'
    'title'
    'title_plain'
    'content'
    'excerpt'
    'date'
    'modified'
    'categories'
    'tags'
    'author'
    'comments'
    'attachments'
    'comment_count'
    'comment_status'
    'custom_fields'
  ]


class Category extends ContentObject
  defaultFields: [
    'id'
    'slug'
    'title'
    'description'
    'parent'
    'post_count'
  ]


class Tag extends ContentObject
  defaultFields: [
    'id'
    'slug'
    'title'
    'description'
    'post_count'
  ]


class Author extends ContentObject
  defaultFields: [
    'id'
    'url'
    'slug'
    'name'
    'first_name'
    'last_name'
    'nickname'
    'description'
  ]


class Comment extends ContentObject
  defaultFields: [
    'id'
    'url'
    'name'
    'date'
    'content'
    'parent'
    'author'
  ]


class Attachment extends ContentObject
  defaultFields: [
    'id'
    'url'
    'slug'
    'title'
    'description'
    'caption'
    'parent'
    'mime_type'
    'images'
  ]


class Posts extends Backbone.Collection
  model: Post

class Categories extends Backbone.Collection
  model: Category

class Tags extends Backbone.Collection
  model: Tag

class Authors extends Backbone.Collection
  model: Author

class Comments extends Backbone.Collection
  model: Comment

class Attachments extends Backbone.Collection
  model: Attachment


###*
 * Handles inter-object relationships, caching, and interacting with the
   backend API
###
class WordPress
  ###*
   * The URL where the backend is.
   * @type {String}
  ###
  backendURL: ''

  ###*
   * The maximum number of posts to ask for in a request. (the `count` param)
   * @type {Number}
  ###
  maxPostsPerRequest: 10

  cache:
    posts: new Posts()
    categories: new Categories()
    tags: new Tags()
    authors: new Authors()
    comments: new Comments()
    attachments: new Attachments()

  constructor: (@backendURL) ->
    for name, collection of @cache
      console.log collection
      collection.on('add', @processObject)

  makeURL: (params) ->
    query = []
    for name, value of params
      query.push "#{name}=#{value}"

    url = @backendURL
    if query.length isnt 0
      url += "?#{query.join('&')}"

    url

  ###*
   * Take an object out of a model (replacing it with an ID) and put the
     removed object into its own collection
   * @param {ContentObject} model
   * @param {String} fieldName The name of the field to abstract.
   * @param {String} [collectionName=fieldName] The name of the collection to
     put the removed object into. If omitted, the fieldName will be used.
  ###
  abstractField: (model, fieldName, collectionName='') ->
    if collectionName is '' then collectionName = fieldName
    field = model.get fieldName
    unless field? then return

    # when adding models, it doesn't matter if it's an array - Backbone deals
    # with that
    model.set fieldName, @cache[collectionName].add(field, merge: true)
    

  ###*
   * Deal with objects that are inside of the model
   * @param {ContentObject} model
  ###
  processObject: (model) =>
    @abstractField model, 'categories'
    @abstractField model, 'tags'
    @abstractField model, 'author', 'authors'
    @abstractField model, 'comments'
    @abstractField model, 'attachments'

  request: (method, params={}, cb) ->
    params['json'] = method
    jsonp(@makeURL(params), {}, cb)

  ###*
   * [getPosts description]
  ###
  getPosts: (query={}) ->
    @request 'get_posts', query, (err, data) =>
      unless err
        @cache.posts.add data['posts']

module.exports = WordPress
