package starling.extensions
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.ImageDecodingPolicy;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import starling.events.EventDispatcher;

	import starling.textures.AtfData;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.textures.TextureOptions;

	[Event(type="starling.events.Event", name="progress")]
	public class AssetManager extends EventDispatcher
	{
		public static const DOWNLOAD_TRIES:int = 3;

		// @see: http://help.adobe.com/en_US/as3/dev/WS5b3ccc516d4fbf351e63e3d118a9b90204-7d66.html
		// @see: http://en.wikipedia.org/wiki/List_of_file_signatures
		public static const IMAGE_FORMAT_SIGNATURES:Array =
			[
				"\u0089PNG\r\n\u001A\n",				// PNG
				"\u00FF\u00D8\u00FF",					// JPG (not full there are 3 forms)
				"\u0047\u0049\u0046\u0038\u0037\u0061",	// GIF87a
				"\u0047\u0049\u0046\u0038\u0039\u0061"	// GIF89a
			];

		protected var _handlers:Vector.<Handler>;
		protected var _registry:Dictionary;
		protected var _shared:Object;

		protected var _checkPolicyFile:Boolean;
		protected var _verbose:Boolean;

		public function AssetManager()
		{
			_registry = new Dictionary();
			_handlers = new Vector.<Handler>();
			_shared = new Object();

			addHandler(loadURL, URLRequest);

			addHandler(decodeStringToURLRequest, String);
			addHandler(decodeByteArrayToTexture, ByteArray);
			addHandler(decodeByteArrayToXML, ByteArray);
			addHandler(decodeByteArrayToJSON, ByteArray);

			addHandler(assembleTextureAtlas, Object);
			addHandler(assembleBitmapFont, Object);
		}

		//
		// Basic API
		//

		public final function getAsset(type:Class, key:String):Object
		{
			return _registry[type] ? _registry[type][key] : null;
		}

		public final function addAsset(type:Class, key:String, asset:Object):void
		{
			_registry[type] ||= new Dictionary();
			_registry[type][key] = asset;

			log("Added " + type.toString().substr(7).substr(0, -1) + "::" + key);
		}

		public function removeAsset(type:Class, key:String):void
		{
			if (type in _registry) delete _registry[type][key]
		}

		public function addHandler(callback:Function, type:Class = null, priority:int = 0):void
		{
			_handlers.push(new Handler(callback, type || Object, priority));
			_handlers.sort(byPriority);
		}

		private function byPriority(h1:Handler, h2:Handler):int
		{
			return h1.priority - h2.priority
		}

		public function handle(asset:Object, key:String = null, options:Object = null):int
		{
			for each (var handler:Handler in _handlers)
			{
				if (asset is handler.type)
				{
					var status:* = null;

					if (handler.callback.length == 1)		status = handler.callback(asset);
					else if (handler.callback.length == 2)	status = handler.callback(asset, key);
					else                            		status = handler.callback(asset, key, options);

					// Prevent next processing
					if (status === true) break;
				}
			}

			return 0;
		}

		//
		// Default handlers
		//

		protected function loadURL(value:URLRequest, key:String, options:Object):void
		{
			download(value, DOWNLOAD_TRIES, function (bytes:ByteArray):void
			{
				handle(bytes, key || getName(value.url), options);
			});
		}

		protected function decodeStringToURLRequest(value:String, key:String, options:Object):void
		{
			handle(new URLRequest(value), key, options);
		}

		protected function decodeByteArrayToTexture(value:ByteArray, key:String, options:Object):void
		{
			if (isBitmapData(value))
			{
				var loaderContext:LoaderContext = new LoaderContext(_checkPolicyFile);
				loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;

				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, complete);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, complete);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
				loader.loadBytes(value, loaderContext);

				function complete(e:Event):void
				{
					loader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, complete);
					loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, complete);
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, complete);

					if (e.type == Event.COMPLETE)
					{
						var bitmap:Bitmap = Bitmap(loader.content);
						var texture:Texture = Texture.fromData(bitmap, options as TextureOptions);
						addAsset(Texture, key, texture);
						handle(texture, key, options);
					}
				}
			}
			else if (AtfData.isAtfData(value))
			{
				var texture:Texture = Texture.fromData(value, options as TextureOptions);
				addAsset(Texture, key, texture);
				handle(texture, key);
			}
		}

		protected function decodeByteArrayToXML(value:ByteArray, key:String):void
		{
			if (checkFirstMeanigfulLetter(value, "<"))
			{
				var xml:XML = null;

				try { xml = new XML(value); }
				catch (e:Error) { /* NOP */ }

				if (xml)
				{
					addAsset(XML, key, xml);
					handle(xml, key);
				}
			}
		}

		protected function decodeByteArrayToJSON(value:ByteArray, key:String):void
		{
			if (checkFirstMeanigfulLetter(value, "{") || checkFirstMeanigfulLetter(value, "["))
			{
				var object:Object = null;

				try { object = JSON.parse(value.toString()); }
				catch (e:Error) { /* NOP */ }

				if (object)
				{
					addAsset(Object, key, object);
					handle(object, key);
				}
			}
		}

		protected function assembleTextureAtlas(value:Object, key:String):void
		{
			var waiting:Object = (_shared["assembleTextureAtlas"] ||= {});

			if (value is XML && XML(value).localName() == "TextureAtlas")
			{
				var textureKey:String = getName(XML(value).@imagePath);
				var texture:Texture = Texture(getAsset(Texture, textureKey));
				if (texture == null) waiting[textureKey] = [key, value]; // XXX: multiple links to one texture
				else importAtlas(key, texture, XML(value));
			}
			else if (value is Texture)
			{
				if (waiting[key] != null)
				{
					var atlasKey:String = waiting[key][0];
					var atlasXML:XML = waiting[key][1];
					importAtlas(atlasKey, Texture(value), atlasXML);
					delete waiting[key];
				}
			}
		}

		protected function assembleBitmapFont(value:Object):void
		{

		}

		//
		// Utility methods
		//

		protected function download(url:URLRequest, tries:int, callback:Function):void
		{
			var urlLoader:URLLoader = new URLLoader();
			var urlStatus:int = 0;

			urlLoader.addEventListener(Event.COMPLETE, urlLoaderComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, urlLoaderComplete);
			urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoaderComplete);
			urlLoader.addEventListener(HTTPStatusEvent.HTTP_STATUS, urlLoaderStatusEvent);

			urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			urlLoader.load(url);

			function urlLoaderStatusEvent(e:HTTPStatusEvent):void
			{
				urlStatus = e.status;
			}

			function urlLoaderComplete(e:Event):void
			{
				urlLoader.removeEventListener(Event.COMPLETE, urlLoaderComplete);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, urlLoaderComplete);
				urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, urlLoaderComplete);
				urlLoader.removeEventListener(HTTPStatusEvent.HTTP_STATUS, urlLoaderStatusEvent);

				if (e.type == Event.COMPLETE)
					callback(urlLoader.data);
				else if (e.type == IOErrorEvent.IO_ERROR && tries>0 && (urlStatus==0 || urlStatus==408 || urlStatus==503))
					download(url, tries-1, callback);
				else
					callback(null);
			}
		}

		protected function isBitmapData(bytes:ByteArray):Boolean
		{
			for each (var signature:String in IMAGE_FORMAT_SIGNATURES)
				if (checkSignature(bytes, signature))
					return true;

			return false;
		}

		protected function importAtlas(key:String, texture:Texture, xml:XML):void
		{
			var atlas:TextureAtlas = new TextureAtlas(texture, xml);
			addAsset(TextureAtlas, key, atlas);

			for each (var textureName:String in atlas.getNames())
				addAsset(Texture, textureName, atlas.getTexture(textureName));
		}

		/** Extracts the base name of a file path or URL, i.e. the file name without extension. */
		protected final function getName(url:String):String
		{
			var NAME_REGEX:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;
			var matches:Array = NAME_REGEX.exec(url);
			if (matches && matches.length > 0) return matches[1];
			else return null;
		}

		/** Check whenever byte array starts with signature. */
		protected final function checkSignature(bytes:ByteArray, signature:String):Boolean
		{
			if (bytes.bytesAvailable < signature.length) return false;

			for (var i:int = 0; i < signature.length; i++)
				if (signature.charCodeAt(i) != bytes[i]) return false;

			return true;
		}

		protected final function checkFirstMeanigfulLetter(bytes:ByteArray, char:String):Boolean
		{
			var start:int = 0;
			var length:int = bytes.length;
			var wanted:int = char.charCodeAt(0);

			// recognize BOMs

			if (length >= 4 &&
				(bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xfe && bytes[3] == 0xff) ||
				(bytes[0] == 0xff && bytes[1] == 0xfe && bytes[2] == 0x00 && bytes[3] == 0x00))
			{
				start = 4; // UTF-32
			}
			else if (length >= 3 && bytes[0] == 0xef && bytes[1] == 0xbb && bytes[2] == 0xbf)
			{
				start = 3; // UTF-8
			}
			else if (length >= 2 &&
					(bytes[0] == 0xfe && bytes[1] == 0xff) || (bytes[0] == 0xff && bytes[1] == 0xfe))
				{
					start = 2; // UTF-16
				}

			// find first meaningful letter

			for (var i:int=start; i<length; ++i)
			{
				var byte:int = bytes[i];
				if (byte == 0 || byte == 10 || byte == 13 || byte == 32) continue; // null, \n, \r, space
				else return byte == wanted;
			}

			return false;
		}

		public function log(message:String):void
		{
			if (_verbose) trace("[AssetManager]", message);
		}
	}
}

class Handler
{
	public var callback:Function;
	public var type:Class;
	public var priority:int;

	public function Handler(callback:Function, type:Class, priority:int)
	{
		this.callback = callback;
		this.type = type;
		this.priority = priority;
	}
}
