(function(){var a,b,c,d,e,f,g,h,i,j,k,l,m={}.hasOwnProperty,n=function(a,b){function d(){this.constructor=a}for(var c in b)m.call(b,c)&&(a[c]=b[c]);return d.prototype=b.prototype,a.prototype=new d,a.__super__=b.prototype,a};a=require("jquery"),h=require("underscore"),b=require("backbone"),g=function(a){return a?(a^Math.random()*16>>a/4).toString(16):([1e7]+1e3+4e3+8e3+1e11).replace(/[018]/g,g)},e=function(a){function b(){return i=b.__super__.constructor.apply(this,arguments),i}return n(b,a),b.prototype.defaults={title:"",url:"",thumb_url:"",caption:"",slug:"",group_id:"",description:""},b.prototype.sync=function(){return!1},b.prototype.initialize=function(){},b}(b.Model),f=function(a){function b(){return j=b.__super__.constructor.apply(this,arguments),j}return n(b,a),b.prototype.tagName="figure",b.prototype.render=function(){return this.el.innerHTML='<a class="fancybox" rel="'+this.model.get("group_id")+'" href="'+this.model.get("url")+'" title="'+this.model.get("title")+'">\n\t<img src="'+this.model.get("thumb_url")+'" alt="" />\n\t<figcaption>'+this.model.get("title")+"</figcaption>\n</a>"},b.prototype.initialize=function(){return this.model.view=this,this.render()},b}(b.View),d=function(a){function b(){return k=b.__super__.constructor.apply(this,arguments),k}return n(b,a),b.prototype.className="gallery",b.prototype.initialize=function(){},b}(b.View),c=function(a){function b(){return l=b.__super__.constructor.apply(this,arguments),l}return n(b,a),b.prototype.model=e,b.prototype.added_photo=function(a){return a.set("group_id",this.group_id),this.view.$el.append((new f({model:a})).el)},b.prototype.initialize=function(){return this.group_id=g(),this.on("add",this.added_photo),this.view=new d({model:this})},b}(b.Collection),module.exports=function(){var b;return b=[],a(".gallery").each(function(d,e){return b[d]=new c,a(e).find("a").each(function(c){var e,f;return f=a(this).attr("href"),e=attachment_index[f],b[d].add({title:e.title,url:f,thumb_url:e.images.thumbnail.url,caption:e.caption,description:e.description,slug:e.slug})}).promise().done(function(){return a(e).replaceWith(b[d].view.el)})})}}).call(this)