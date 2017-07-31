package starling.extensions
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.utils.AssetManager;

	import talon.Node;
	import talon.utils.StyleSheet;
	import talon.utils.TalonFactoryBase;

	public class TalonFactory extends TalonFactoryBase
	{
		public function TalonFactory()
		{
			setTerminal("div", TalonSprite);
			setTerminal("txt", TalonTextField);
			setTerminal("img", TalonImage);

			// FIXME: Remove
			setTerminal("node", TalonSprite);
			setTerminal("label", TalonTextField);
			setTerminal("image", TalonImage);
		}

		public function build(xmlOrKey:Object, includeStyleSheet:Boolean = true, includeResources:Boolean = true):ITalonElement
		{
			return createInternal(xmlOrKey, includeStyleSheet, includeResources) as ITalonElement;
		}

		// template methods

		protected override function getNode(element:*):Node
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

		/** Import all textures, templates, css from asset manager. */
		public function importAssetManager(assets:AssetManager):void
		{
			var name:String;
			var names:Vector.<String> = new Vector.<String>();
			
			// Textures
			names.length = 0;
			names = assets.getTextureNames("", names);

			for each (name in names)
				addResource(name, assets.getTexture(name));

			// Templates & Libraries
			names.length = 0;
			names = assets.getXmlNames("", names);
			
			for each (name in names)
			{
				var xml:XML = assets.getXml(name);
				var xmlName:String = xml.name();
				if (xmlName == TalonFactoryBase.TAG_TEMPLATE) addTemplate(xml);
				else if (xmlName == TalonFactoryBase.TAG_LIBRARY) importLibrary(xml);
			}
			
			// CSS & Properties
			// TODO
		}
		
		public function importArchiveAsync(bytes:ByteArray, onProgress:Function):void
		{
			var hasFZipLibrary:Boolean = ApplicationDomain.currentDomain.hasDefinition("deng.fzip.FZip");
			if (hasFZipLibrary == false) throw new Error("FZip library required for archive import");
			if (bytes == null) throw new ArgumentError("Parameter bytes must be non-null");

			var manager:AssetManagerExtended = new AssetManagerExtended();
			manager.enqueueZip(bytes);
			manager.loadQueue(onProgressInner);

			function onProgressInner(ratio:Number):void
			{
				if (ratio == 1)
				{
					importAssetManager(manager);
					
					var styleNames:Vector.<String> = manager.getCssNames();
					for each (var styleName:String in styleNames)
						addStyle(new StyleSheet(manager.getCss(styleName)));

					var propertiesNames:Vector.<String> = manager.getPropertiesNames();
					for each (var propertiesName:String in propertiesNames)
						importResources(manager.getProperties(propertiesName));
				}

				if (onProgress.length == 1)
					onProgress(ratio);
				else if (ratio == 1)
					onProgress();
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

	public function AssetManagerExtended(getNameCallback:Function = null)
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