package starling.extensions
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;

	import talon.Node;
	import starling.extensions.ITalonElement;

	import talon.utils.TMLFactory;

	public class TalonFactory extends TMLFactory
	{
		public function TalonFactory()
		{
			addTerminal("node", TalonSpriteElement);
			addTerminal("label", TalonTextFieldElement);
			addTerminal("image", TalonImageElement);
		}

		public function createElement(source:Object, includeStyleSheet:Boolean = true, includeResources:Boolean = true):ITalonElement
		{
			return create(source, includeStyleSheet, includeResources) as ITalonElement;
		}

		// template methods

		protected override function getElementNode(element:*):Node
		{
			return ITalonElement(element).node;
		}

		protected override function addChild(parent:*, child:*):void
		{
			var parentAsDisplayObject:DisplayObjectContainer = DisplayObjectContainer(parent);
			var childAsDisplayObject:DisplayObject = DisplayObject(child);
			parentAsDisplayObject.addChild(childAsDisplayObject);
		}

		// integration with starling asset manager

		public function addArchiveContentAsync(bytes:ByteArray, complete:Function):void
		{
			var hasFZipLibrary:Boolean = ApplicationDomain.currentDomain.hasDefinition("deng.fzip.FZip");
			if (hasFZipLibrary == false) throw new Error("FZip library required for archive import");

			if (bytes == null) throw new ArgumentError("Parameter bytes must be non-null");

			var manager:AssetManagerExtended = new AssetManagerExtended(null /*getNameCallback*/);
			manager.verbose = false;
			manager.useMipMaps = false; // FIXME: Bugs with MipMaps
			manager.enqueueZip(bytes);
			manager.loadQueue(onProgress);

			function onProgress(ratio:Number):void
			{
				if (ratio == 1)
				{
					onAssetManagerComplete(manager);
					complete();
				}
			}
		}

		private function onAssetManagerComplete(manager:AssetManagerExtended):void
		{
			var textureIds:Vector.<String> = manager.getTextureNames();
			for each (var textureId:String in textureIds)
			{
				addResourceToScope(textureId, manager.getTexture(textureId));
			}

			var styleIds:Vector.<String> = manager.getCssNames();
			for each (var styleId:String in styleIds)
			{
				addStyleSheet(manager.getCss(styleId));
			}

			var xmlIds:Vector.<String> = manager.getXmlNames();
			for each (var xmlId:String in xmlIds)
			{
				var xml:XML = manager.getXml(xmlId);
				if (xml.name() == TMLFactory.TAG_TEMPLATE) addTemplate(xml);
				if (xml.name() == TMLFactory.TAG_LIBRARY) addLibrary(xml);
			}

			var propertiesIds:Vector.<String> = manager.getPropertiesNames();
			for each (var propertiesId:String in propertiesIds)
			{
				var properties:Object = manager.getProperties(propertiesId);
				for (var propertyName:String in properties)
				{
					var propertyValue:String = properties[propertyName];
					addResourceToScope(propertyName, propertyValue);
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

import talon.utils.ParseUtil;

class AssetManagerExtended extends AssetManager
{
	private static const PNG:String = "\u0089PNG\r\n\u001A\n";
	private static const JPG:String = "\u00FF\u00D8\u00FF";
	private static const GIF87a:String = "\u0047\u0049\u0046\u0038\u0037\u0061";
	private static const GIF89a:String = "\u0047\u0049\u0046\u0038\u0039\u0061";

	private var mGetNameCallback:Function;

	private var mCss:Dictionary;
	private var mCssGuess:Dictionary;

	private var mProperties:Dictionary;
	private var mPropertiesGuess:Dictionary;

	public function AssetManagerExtended(getNameCallback:Function)
	{
		mGetNameCallback = getNameCallback;
		mCss = new Dictionary();
		mCssGuess = new Dictionary(true);
		mProperties = new Dictionary();
		mPropertiesGuess = new Dictionary(true);
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
				mCssGuess[asset] = name;

			if (extension == "properties")
				mPropertiesGuess[asset] = name;

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
					else if (asset in mPropertiesGuess)
					{
						addProperties(mPropertiesGuess[asset],  ParseUtil.parseProperties(asset.toString()));
						delete mPropertiesGuess[asset];
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
			{
				onComplete(asset);
			}
			else
			{
				SystemUtil.executeWhenApplicationIsActive(onComplete, asset);
			}
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

	/** Removes a certain CSS object. */
	public function removeCss(name:String):void
	{
		log("Removing css '" + name + "'");
		delete mCss[name];
	}

	/** Returns an CSS with a certain name, or null if it's not found. */
	public function getCss(name:String):String
	{
		return mCss[name];
	}

	/** Returns all CSS names that start with a certain string, sorted alphabetically.
	 *  If you pass a result vector, the names will be added to that vector. */
	public function getCssNames(prefix:String = "", result:Vector.<String> = null):Vector.<String>
	{
		return getDictionaryKeys(mCss, prefix, result);
	}

	//
	// Properties Extension
	//
	/** Register an Properties object under a certain name. It will be available right away.
	 *  If the name was already taken, the existing Properties will be disposed and replaced
	 *  by the new one. */
	public function addProperties(name:String, properties:Object):void
	{
		log("Adding properties '" + name + "'");

		if (name in mProperties)
		{
			log("Warning: name was already in use; the previous properties will be replaced.");
		}

		mProperties[name] = properties;
	}

	/** Removes a certain properties object. */
	public function removeProperties(name:String):void
	{
		log("Removing properties '" + name + "'");
		delete mProperties[name];
	}

	/** Returns an properties with a certain name, or null if it's not found. */
	public function getProperties(name:String):Object
	{
		return mProperties[name];
	}

	/** Returns all Properties names that start with a certain string, sorted alphabetically.
	 *  If you pass a result vector, the names will be added to that vector. */
	public function getPropertiesNames(prefix:String = "", result:Vector.<String> = null):Vector.<String>
	{
		return getDictionaryKeys(mProperties, prefix, result);
	}

	//
	// Misc
	//
	/** NB! Copy-Paste from super. */
	private function getDictionaryKeys(dictionary:Dictionary, prefix:String = "", result:Vector.<String> = null):Vector.<String>
	{
		if (result == null) result = new <String>[];

		for (var name:String in dictionary)
		{
			if (name.indexOf(prefix) == 0)
			{
				result[result.length] = name;
			}
		} // avoid 'push'

		result.sort(Array.CASEINSENSITIVE);
		return result;
	}
}