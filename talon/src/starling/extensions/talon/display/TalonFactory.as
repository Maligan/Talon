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

		/** Trivial prototype. */
		public function addPrototype(id:String, xml:XML):void
		{
			_prototypes[id] = xml;
		}

		/** Trivial resource. */
		public function addResource(id:String, resource:*):void
		{
			_resources[id] = resource;
		}

		/** Trivial stylesheet. */
		public function addStyleSheet(css:String):void
		{
			_style.parse(css);
		}

		/** Complex library. */
		public function addLibrary(xml:XML):void
		{

		}

		/** Complex archive. Import all files from zip archive to library. */
		public function addArchiveAsync(bytes:ByteArray, getNameCallback:Function = null):void
		{
			if (bytes == null) throw new ArgumentError("Parameter bytes must be non-null");

			var manager:AssetManagerExtended = new AssetManagerExtended();
			manager.enqueueZip(bytes);
			manager.loadQueue(onProgress);

			function onProgress(ratio:Number):void
			{
				if (ratio == 1)
					onZipLoaderComplete(manager);
			}
		}

		/** Get basename (filename without extension). */
		protected final function getName(path:String):String
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

		private function onZipLoaderComplete(manager:AssetManagerExtended):void
		{

			trace('complete');

//			for (var prototypeId:String in loader.prototypes)
//				addPrototype(prototypeId, loader.prototypes[prototypeId]);
//
//			for (var stylesheetId:String in loader.stylesheets)
//				addStyleSheet(loader.stylesheets[stylesheetId]);
//
//			for (var resourceId:String in loader.resources)
//				addResource(resourceId, loader.resources[resourceId]);
		}
	}
}

import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.IOErrorEvent;
import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import starling.events.Event;
import starling.utils.AssetManager;
import starling.utils.SystemUtil;

class AssetManagerExtended extends AssetManager
{
	private static const PNG:String = "\u0089PNG\r\n\u001A\n";
	private static const JPG:String = "\u00FF\u00D8\u00FF";
	private static const GIF87a:String = "\u0047\u0049\u0046\u0038\u0037\u0061";
	private static const GIF89a:String = "\u0047\u0049\u0046\u0038\u0039\u0061";

	public function enqueueZip(bytes:ByteArray):void
	{
		var zip:FZip = new FZip();
		zip.loadBytes(bytes);

		var numFiles:int = zip.getFileCount();
		for (var i:int = 0; i < numFiles; i++)
		{
			var file:FZipFile = zip.getFileAt(i);
			enqueueWithName(file.content, getBasenameFromUrl(file.filename));
		}
	}

	protected override function loadRawAsset(rawAsset:Object, onProgress:Function, onComplete:Function):void
	{
		var loaderInfo:LoaderInfo = null;
		var hasImageSignature:Boolean = false;

		if (rawAsset is ByteArray)
		{
			var bytes:ByteArray = ByteArray(rawAsset);
			hasImageSignature ||= hasSignature(bytes, PNG);
			hasImageSignature ||= hasSignature(bytes, JPG);
			hasImageSignature ||= hasSignature(bytes, GIF87a);
			hasImageSignature ||= hasSignature(bytes, GIF89a);
		}

		if (hasImageSignature)
		{
			var loaderContext:LoaderContext = new LoaderContext(checkPolicyFile);
			var loader:Loader = new Loader();
			loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			loaderInfo = loader.contentLoaderInfo;
			loaderInfo.addEventListener(Event.IO_ERROR, onIoError);
			loaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
			loader.loadBytes(bytes, loaderContext);
		}
		else
		{
			super.loadRawAsset(rawAsset, onProgress, onComplete);
		}

		function onIoError(event:IOErrorEvent):void
		{
			log("IO error: " + event.text);
			dispatchEventWith(Event.IO_ERROR);
			complete(null);
		}

		function onLoaderComplete(event:Object):void
		{
			complete(event.target.content);
		}

		function complete(asset:Object):void
		{
			loaderInfo.removeEventListener(Event.IO_ERROR, onIoError);
			loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);

			// On mobile, it is not allowed / endorsed to make stage3D calls while the app
			// is in the background. Thus, we pause queue processing if that's the case.

			if (SystemUtil.isDesktop)
				onComplete(asset);
			else
				SystemUtil.executeWhenApplicationIsActive(onComplete, asset);
		}
	}

	/** Check whenever byte array starts with signature. */
	private function hasSignature(source:ByteArray, signature:String):Boolean
	{
		if (source.bytesAvailable < signature.length) return false;

		for (var i:int = 0; i < signature.length; i++)
		{
			if (signature.charCodeAt(i) != source[i]) return false;
		}

		return true;
	}
}