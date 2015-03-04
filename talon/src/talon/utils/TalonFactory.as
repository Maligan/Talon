package talon.utils
{
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.events.EventDispatcher;

	import talon.Attribute;

	import talon.Node;
	import talon.StyleSheet;
	import talon.starling.*;

	public class TalonFactory extends EventDispatcher
	{
		// Special keyword-tags
		private static const TAG_DEFINE:String = "define";
		private static const TAG_DEFINITION:String = "definition";
		private static const TAG_REWRITE:String = "rewrite";

		// Special keyword-attributes
		private static const ATT_ID:String = "id";
		private static const ATT_TYPE:String = "type";
		private static const ATT_BASE:String = "base";
		private static const ATT_REF:String = "ref";

		protected var _linkageByDefault:Class;
		protected var _linkage:Dictionary = new Dictionary();
		protected var _prototypes:Dictionary = new Dictionary();
		protected var _resources:Object = new Dictionary();
		protected var _style:StyleSheet = new StyleSheet();
		protected var _defines:Dictionary;

		public function TalonFactory(defaultLinkageClass:Class = null):void
		{
			_linkageByDefault = defaultLinkageClass || SpriteElement;
			setLinkage("node", SpriteElement);
			setLinkage("image", ImageElement);
			setLinkage("label", TextFieldElement);
		}

		public function build(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):DisplayObject
		{
			if (id == null) throw new ArgumentError("Parameter id must be non-null");
			var config:XML = _prototypes[id];
			if (config == null) throw new ArgumentError("Prototype by id: " + id + " not found");

			var element:DisplayObject = fromXML_OLD(config);
			if (element is ITalonElement)
			{
				includeResources && ITalonElement(element).node.setResources(_resources);
				includeStyleSheet && ITalonElement(element).node.setStyleSheet(_style);
			}

			return element;
		}

		//
		// Factory
		//
		private function fromXML(xml:XML, rewrite:Object):Node
		{
			var result:Node;
			var type:String = xml.name();
			rewrite = merge(rewrite, xml.child(TAG_REWRITE));

			if (type == TAG_DEFINE)
			{
				var base:String = xml.attribute(ATT_BASE).toString();
				result = fromXML(base ? getDefinition(base) : xml.*[0], rewrite);
				result.setAttribute(Attribute.TYPE, xml.attribute(ATT_TYPE) || type);
			}
			else if (type == TAG_DEFINITION || getDefinitionIdByType(type) != null)
			{
				var ref:String = getDefinitionIdByType(type) || xml.attribute(ATT_REF).toString();
				result = fromXML(getDefinition(ref), rewrite);
				for each (var attribute:XML in xml.attributes()) result.setAttribute(attribute.name(), attribute.toString());
			}
			else
			{
				result = new Node();
				result.setAttribute(Attribute.TYPE, type);
				var children:XMLList = rewrite[xml.attribute(ATT_ID).toString()] || xml.children();
				for each (var attribute:XML in xml.attributes()) result.setAttribute(attribute.name(), attribute.toString());
				for each (var child:XML in children) result.addChild(fromXML(child, rewrite));
			}

			return result;
		}

		private function merge(base:Object, children:XMLList):Object
		{
			if (children.length() == 0) return base;

			var result:Object = new Object();
			for (var id:String in base) result[id] = base[id];
			for each (var rewrite:XML in children) result[rewrite.attribute(ATT_REF)] = rewrite.children();
			return result;
		}

		private function getDefinition(id:String):XML { return _defines[id]; }
		private function getDefinitionIdByType(type:String):String { return null; }

		//
		// Old
		//
		private function fromXML_OLD(xml:XML):DisplayObject
		{
			var elementType:String = xml.name();
			var elementClass:Class = _linkage[elementType] || _linkageByDefault;
			var element:DisplayObject = new elementClass();

			if (element is ITalonElement)
			{
				var node:Node = ITalonElement(element).node;
				node.setAttribute(Attribute.TYPE, elementType);

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
					var childElement:DisplayObject = fromXML_OLD(childXML);
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
				if (xml.localName() == "prototype")
				{
					var name:String = xml.@id;
					var body:XML = xml.*[0];
					addPrototype(name, body);
				}
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