package talon.utils
{
	import talon.Attribute;
	import talon.enums.BindMode;
	import talon.starling.*;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	import talon.Node;

	import talon.StyleSheet;

	/** TODO: Move to starling subpackage. */
	public class TalonFactory extends EventDispatcher
	{
		protected var _parser:TMLParser;
		protected var _parserStack:Vector.<DisplayObject>;
		protected var _parserProduct:DisplayObject;

		protected var _linkage:Dictionary = new Dictionary();
		protected var _linkageByDefault:Class;
		protected var _templates:Dictionary = new Dictionary();
		protected var _resources:Object = new Dictionary();
		protected var _style:StyleSheet = new StyleSheet();

		public function TalonFactory(linkageByDefault:Class = null):void
		{
			_linkageByDefault = linkageByDefault || SpriteElement;

			_parser = new TMLParser();
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onElementBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onElementEnd);
			_parserStack = new <DisplayObject>[];

			addTerminal("node", SpriteElement);
			addTerminal("image", ImageElement);
			addTerminal("label", TextFieldElement);
		}

		//
		// Factory
		//

		public function build(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):DisplayObject
		{
			// _parserStack if is not empty?
			_parser.parseTemplate(id);

			var result:DisplayObject = _parserProduct;
			_parserProduct = null;

			var node:Node = result is ITalonElement ? ITalonElement(result).node : null;
			if (node)
			{
				includeResources    && node.setResources(_resources);
				includeStyleSheet   && node.setStyleSheet(_style);
			}

			return result;
		}

		private function onElementBegin(e:Event):void
		{
			var attributes:Object = e.data;
			var type:String = attributes["type"];
			var typeClass:Class = _linkage[type] || _linkageByDefault;

			var element:DisplayObject = new typeClass();
			var node:Node = element is ITalonElement ? ITalonElement(element).node : null;

			if (node)
			{
				for (var key:String in attributes)
				{
					var value:String = attributes[key];
					var func:Array = StringUtil.parseFunction(value);
					if (func && func[0] == "bind")
					{
						var parent:ITalonElement = _parserStack[_parserStack.length - 1] as ITalonElement;
						var source:Attribute = parent.node.getOrCreateAttribute(func[1]);
						var target:Attribute = node.getOrCreateAttribute(key);

						var mode:String = func.length > 2 ? func[2] : BindMode.ONCE;
						if (BindMode.isValid(mode) == false) new Error("Unknown bind mode: '" + mode + "'");

						switch (mode)
						{
							case BindMode.ONCE:
								target.assigned = source.value;
								break;
							case BindMode.ONE_WAY:
								target.bind(source, bindGetter(source), bindSetter(target));
								break;
							case BindMode.TWO_WAY:
								source.bind(target, bindGetter(source), bindSetter(source));
								break;
						}
					}
					else
					{
						node.setAttribute(key, value);
					}
				}
			}

			var parentAsDisplayObject:DisplayObjectContainer = _parserStack.length ? _parserStack[_parserStack.length-1] as DisplayObjectContainer : null;
			if (parentAsDisplayObject)
				parentAsDisplayObject.addChild(element);

			_parserStack.push(element);
		}

		private function bindGetter(attr:Attribute):Function { return function():String { return attr.value } }
		private function bindSetter(attr:Attribute):Function { return function(value:String):void { /*attr.assigned = value;*/ } }

		private function onElementEnd(e:Event):void
		{
			_parserProduct = _parserStack.pop();
		}

		//
		// Linkage
		//
		public function addTerminal(id:String, displayObjectClass:Class):void
		{
			_parser.terminals.push(id);
			_linkage[id] = displayObjectClass;
		}

		//
		// Library
		//
		/** Trivial template. */
		public function addTemplate(xml:XML):void
		{
			var type:String = xml.name();
			if (type != "template") throw new ArgumentError("Root node must be <template>");

			var id:String = xml.@id;
			if (id == null) throw new ArgumentError("Template must contains id attribute");

			if (xml.children().length() != 1) throw new ArgumentError("Template must contains one child");
			if (_parser.templates[id] != null) throw new ArgumentError("Template with id " + id + " already exists");

			_parser.templates[id] = xml.children()[0];
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

		/** Complex archive. Import all files from zip archive to library. */
		public function addArchiveAsync(bytes:ByteArray, getNameCallback:Function = null):void
		{
			var hasFZipLibrary:Boolean = ApplicationDomain.currentDomain.hasDefinition("deng.fzip.FZip");
			if (hasFZipLibrary == false) throw new Error("FZip library required for archive import");

			if (bytes == null) throw new ArgumentError("Parameter bytes must be non-null");

			var manager:AssetManagerExtended = new AssetManagerExtended(getNameCallback);
			manager.verbose = false;
			manager.enqueueZip(bytes);
			manager.loadQueue(onProgress);

			function onProgress(ratio:Number):void
			{
				if (ratio == 1)
				{
					onAssetManagerComplete(manager);
					dispatchEventWith(Event.COMPLETE);
				}
			}
		}

		private function onAssetManagerComplete(manager:AssetManagerExtended):void
		{
			var textureIds:Vector.<String> = manager.getTextureNames();
			for each (var textureId:String in textureIds) addResource(textureId, manager.getTexture(textureId));

			var styleIds:Vector.<String> = manager.getCssNames();
			for each (var styleId:String in styleIds) addStyleSheet(manager.getCss(styleId));

			var xmlIds:Vector.<String> = manager.getXmlNames();
			for each (var xmlId:String in xmlIds)
			{
				var xml:XML = manager.getXml(xmlId);
				if (xml.name() == "template") addTemplate(xml);
			}
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
import flash.utils.Dictionary;

import starling.events.Event;
import starling.utils.AssetManager;
import starling.utils.SystemUtil;

class AssetManagerExtended extends AssetManager
{
	private static const PNG:String = "\u0089PNG\r\n\u001A\n";
	private static const JPG:String = "\u00FF\u00D8\u00FF";
	private static const GIF87a:String = "\u0047\u0049\u0046\u0038\u0037\u0061";
	private static const GIF89a:String = "\u0047\u0049\u0046\u0038\u0039\u0061";

	private var mGetNameCallback:Function;
	private var mCss:Dictionary;
	private var mCssGuess:Dictionary; // TODO: Remove guesses, define css from content

	public function AssetManagerExtended(getNameCallback:Function)
	{
		mGetNameCallback = getNameCallback;
		mCss = new Dictionary();
		mCssGuess = new Dictionary(true);
	}

	public function enqueueZip(bytes:ByteArray):void
	{
		var zip:FZip = new FZip();
		zip.loadBytes(bytes);

		var numFiles:int = zip.getFileCount();
		for (var i:int = 0; i < numFiles; i++)
		{
			var file:FZipFile = zip.getFileAt(i);

			var name:String = getBasenameFromUrl(file.filename);
			var extension:String = getExtensionFromUrl(file.filename);
			var asset:ByteArray = file.content;

			if (extension == "css")
			{
				mCssGuess[asset] = name;
			}

			enqueueWithName(asset, name);
		}
	}

	protected override function loadRawAsset(rawAsset:Object, onProgress:Function, onComplete:Function):void
	{
		var loaderInfo:LoaderInfo = null;

		if (rawAsset is ByteArray)
		{
			var bytes:ByteArray = ByteArray(rawAsset);

			var hasImageSignature:Boolean = false;
			hasImageSignature ||= hasSignature(bytes, PNG);
			hasImageSignature ||= hasSignature(bytes, JPG);
			hasImageSignature ||= hasSignature(bytes, GIF87a);
			hasImageSignature ||= hasSignature(bytes, GIF89a);

			if (hasImageSignature)
			{
				var loaderContext:LoaderContext = new LoaderContext(checkPolicyFile);
				var loader:Loader = new Loader();
				loaderContext.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
				loaderInfo = loader.contentLoaderInfo;
				loaderInfo.addEventListener(Event.IO_ERROR, onIoError);
				loaderInfo.addEventListener(Event.COMPLETE, onLoaderComplete);
				loader.loadBytes(bytes, loaderContext);

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
			}
			else
			{
				var original:Function = onComplete;

				onComplete = function (asset:Object):void
				{
					if (asset in mCssGuess)
					{
						addCss(mCssGuess[asset], asset.toString());
						delete mCssGuess[asset];
						original(null);
					}
					else
					{
						original(asset);
					}
				};

				complete(bytes);
			}
		}
		else
		{
			super.loadRawAsset(rawAsset, onProgress, onComplete);
		}

		/** NB! Copy-Paste from super. */
		function complete(asset:Object):void
		{
			if (loaderInfo)
			{
				loaderInfo.removeEventListener(Event.IO_ERROR, onIoError);
				loaderInfo.removeEventListener(Event.COMPLETE, onLoaderComplete);
			}

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

	protected override function getBasenameFromUrl(url:String):String
	{
		return mGetNameCallback ? mGetNameCallback(url) : super.getBasenameFromUrl(url);
	}

	//
	// CSS Extension
	//
	/** Register an CSS string under a certain name. It will be available right away.
	 *  If the name was already taken, the existing CSS will be disposed and replaced
	 *  by the new one. */
	public function addCss(name:String, css:String):void
	{
		log("Adding CSS '" + name + "'");

		if (name in mCss)
		{
			log("Warning: name was already in use; the previous CSS will be replaced.");
		}

		mCss[name] = css;
	}

	/** Removes a certain Css object. */
	public function removeCss(name:String):void
	{
		log("Removing css '"+ name + "'");
		delete mCss[name];
	}

	/** Returns an CSS with a certain name, or null if it's not found. */
	public function getCss(name:String):String
	{
		return mCss[name];
	}

	/** Returns all CSS names that start with a certain string, sorted alphabetically.
	 *  If you pass a result vector, the names will be added to that vector. */
	public function getCssNames(prefix:String="", result:Vector.<String>=null):Vector.<String>
	{
		return getDictionaryKeys(mCss, prefix, result);
	}

	/** NB! Copy-Paste from super. */
	private function getDictionaryKeys(dictionary:Dictionary, prefix:String="", result:Vector.<String>=null):Vector.<String>
	{
		if (result == null) result = new <String>[];

		for (var name:String in dictionary)
			if (name.indexOf(prefix) == 0)
				result[result.length] = name; // avoid 'push'

		result.sort(Array.CASEINSENSITIVE);
		return result;
	}
}