package starling.extensions.talon.display
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.core.StyleSheet;

	public class TalonFactory extends EventDispatcher
	{
		protected var _linkageByDefault:Class;
		protected var _linkage:Dictionary = new Dictionary();
		protected var _prototypes:Dictionary = new Dictionary();
		protected var _resources:Dictionary = new Dictionary();
		protected var _style:StyleSheet = new StyleSheet();

		public function TalonFactory(defaultLinkageClass:Class = null):void
		{
			_linkageByDefault = defaultLinkageClass || TalonSprite;
			setLinkage("node", TalonSprite);
			setLinkage("label", TalonTextField);
		}

		public function build(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):DisplayObject
		{
			if (id == null) throw new ArgumentError("Parameter id must be non-null");
			var config:XML = _prototypes[id];
			if (config == null) throw new ArgumentError("Prototype by id: " + id + " not found");

			var element:DisplayObject = fromXML(config);
			if (element is ITalonTarget)
			{
				includeResources && ITalonTarget(element).node.setResources(_resources);
				includeStyleSheet && ITalonTarget(element).node.setStyleSheet(_style);
			}

			return element;
		}

		private function fromXML(xml:XML):DisplayObject
		{
			var elementType:String = xml.name();
			var elementClass:Class = _linkage[elementType] || _linkageByDefault;
			var element:DisplayObject = new elementClass();

			if (element is ITalonTarget)
			{
				var node:Node = ITalonTarget(element).node;
				node.setAttribute("type", elementType);

				for each (var attribute:XML in xml.attributes())
				{
					var name:String = attribute.name();
					var value:String = attribute.valueOf();
					node.setAttribute(name, value);
				}
			}

			if (element is DisplayObjectContainer)
			{
				var container:DisplayObjectContainer = DisplayObjectContainer(element);
				for each (var childXML:XML in xml.children())
				{
					var childElement:DisplayObject = fromXML(childXML);
					container.addChild(childElement);
				}
			}

			return element;
		}

		//
		// Linkage
		//
		public function setLinkage(type:String, displayObjectClass:Class):void
		{
			_linkage[type] = displayObjectClass;
		}

		//
		// Library
		//
		public function addPrototype(id:String, xml:XML):void
		{
			_prototypes[id] = xml;
		}

		public function addResource(id:String, resource:*):void
		{
			_resources[id] = resource;
		}

		public function addStyleSheet(css:String):void
		{
			_style.parse(css);
		}

		/** Import all files from zip archive to library. */
		public function addArchiveAsync(bytes:ByteArray, getNameCallback:Function = null):void
		{
			if (bytes == null) throw new ArgumentError("Parameter bytes must be non-null");

			var loader:ZipLoader = new ZipLoader(getNameCallback || getBasename);
			loader.addEventListener(Event.COMPLETE, onZipLoaderComplete);
			loader.addEventListener(Event.COMPLETE, dispatchEvent);
			loader.loadBytes(bytes);
		}

		/** Get filename without extension. */
		private function getBasename(path:String):String
		{
			var regexp:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;
			var matches:Array = regexp.exec(path);
			if (matches && matches.length > 0)
			{
				return matches[1];
			}
			else
			{
				return null;
			}
		}

		private function onZipLoaderComplete(e:*):void
		{
			var loader:ZipLoader = ZipLoader(e.target);

			for (var prototypeId:String in loader.prototypes)
				addPrototype(prototypeId, loader.prototypes[prototypeId]);

			for (var stylesheetId:String in loader.stylesheets)
				addStyleSheet(loader.stylesheets[stylesheetId]);

			for (var resourceId:String in loader.resources)
				addResource(resourceId, loader.resources[resourceId]);
		}
	}
}

import deng.fzip.FZip;
import deng.fzip.FZipErrorEvent;
import deng.fzip.FZipFile;

import flash.display.Bitmap;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

import starling.events.EventDispatcher;
import starling.textures.AtfData;
import starling.textures.Texture;

class ZipLoader extends EventDispatcher
{
	private var _resources:Dictionary = new Dictionary();
	private var _prototypes:Dictionary = new Dictionary();
	private var _stylesheets:Dictionary = new Dictionary();
	private var _fonts:Dictionary = new Dictionary();

	private var _getNameCallback:Function;
	private var _taskCount:int = 0;

	public function ZipLoader(getNameCallback:Function):void
	{
		_getNameCallback = getNameCallback;
	}

	public function loadBytes(bytes:ByteArray):void
	{
		var zip:FZip = new FZip();
		zip.addEventListener(FZipErrorEvent.PARSE_ERROR, onParseError);
		zip.loadBytes(bytes);
		parse(zip);

		function onParseError(e:Event):void
		{
			throw new Error("Zip parse error");
		}
	}

	private function parse(zip:FZip):void
	{
		taskBegin();

		var numFiles:int = zip.getFileCount();
		for (var i:int = 0; i < numFiles; i++)
		{
			var file:FZipFile = zip.getFileAt(i);
			var id:String = _getNameCallback(file.filename);

			if (isImage(file))
			{
				decodeTexture(id, file);
			}
			else
			{
				if (isXML(file))
				{
					var xml:XML = new XML(file.content);
					if (xml.name() == "prototype")
					{
						_prototypes[xml.@id.toString()] = xml.*[0];
					}
					if (xml.name() == "font")
					{

					}
					else
					{
						_resources[id] = xml;
					}
				}
				else
				{
					if (isCSS(file))
					{
						_stylesheets[id] = file.content.toString();
					}
					else
					{
						_resources[id] = file.content;
					}
				}
			}
		}

		taskEnd();
	}

	private function isImage(file:FZipFile):Boolean
	{
		if (file.filename.indexOf(".png") != -1) return true;
		if (file.filename.indexOf(".jpg") != -1) return true;
		if (file.filename.indexOf(".gif") != -1) return true;
		if (file.filename.indexOf(".atf") != -1) return true;
		return false;
	}

	private function isXML(file:FZipFile):Boolean
	{
		if (file.filename.indexOf(".xml") != -1) return true;
		return false;
	}

	private function isCSS(file:FZipFile):Boolean
	{
		if (file.filename.indexOf(".css") != -1) return true;
		return false;
	}

	private function decodeTexture(id:String, file:FZipFile):void
	{
		taskBegin();

		var bytes:ByteArray = file.content;

		if (AtfData.isAtfData(bytes))
		{
			_resources[id] = Texture.fromAtfData(bytes, 1, true, taskEnd)
		}
		else
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaderComplete);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onLoaderComplete);

			var context:LoaderContext = new LoaderContext();
			context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;

			loader.loadBytes(bytes, context);
		}

		function onLoaderComplete(e:Event):void
		{
			if (e.type == Event.COMPLETE)
			{
				_resources[id] = Texture.fromBitmap(loader.content as Bitmap);
			}
			else
			{
				trace("[TalonFactory]", "Error while decoding bitmap")
			}

			taskEnd();
		}
	}

	private function taskBegin():void { ++_taskCount; }

	private function taskEnd():void { if (--_taskCount == 0) dispatchEventWith(Event.COMPLETE); }

	//
	// Results
	//
	public function get resources():Dictionary
	{
		return _resources;
	}

	public function get prototypes():Dictionary
	{
		return _prototypes;
	}

	public function get stylesheets():Dictionary
	{
		return _stylesheets;
	}
}