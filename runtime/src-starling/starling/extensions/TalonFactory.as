package starling.extensions
{
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.utils.AssetManager;

	import talon.core.Node;
	import talon.utils.TalonFactoryBase;

	/** End point talon runtime class for build UI in Starling Framework. */
	public class TalonFactory extends TalonFactoryBase
	{
		/** @private */
		public function TalonFactory()
		{
			setTerminal("div", TalonSprite);
			setTerminal("txt", TalonTextField);
			setTerminal("img", TalonQuad);
		}

		/** Create display object from template or xml-markup. */
		public function build(xmlOrKey:Object, includeStyleSheet:Boolean = true, includeResources:Boolean = true):ITalonDisplayObject
		{
			return buildObject(xmlOrKey, includeStyleSheet, includeResources) as ITalonDisplayObject;
		}

		// override methods
		
		/** @private */
		protected override function getNode(element:*):Node
		{
			return ITalonDisplayObject(element).node;
		}

		/** @private */
		protected override function addChild(parent:*, child:*):void
		{
			var parentAsDisplayObject:DisplayObjectContainer = DisplayObjectContainer(parent);
			var childAsDisplayObject:DisplayObject = DisplayObject(child);
			parentAsDisplayObject.addChild(childAsDisplayObject);
		}

		// integration with starling asset manager

		/** Import all textures and caches into factory. */
		public function importAssetManager(assets:AssetManager):void
		{
			var name:String;
			var names:Vector.<String> = new Vector.<String>();
			
			// Textures
			names.length = 0;
			names = assets.getTextureNames("", names);
			for each (name in names)
				addResource(name, assets.getTexture(name));

			// Caches
			names.length = 0;
			names = assets.getObjectNames("", names);
			for each (name in names)
			{
				var object:Object = assets.getObject(name);
				if (object["type"] == "application/x-talon-cache")
					importCache(object);
			}
		}
		
		/** Simplest method for prepare TalonFactory:
		 * 
		 * 1) Extract files from zip archive
		 * 2) Load them with AssetManager
		 * 3) Import AssetManager into factory (@see importAssetManager).
		 * 
		 * This method works only if you link FZip library (https://github.com/claus/fzip) int swf. */
		public function importArchiveAsync(bytes:ByteArray, onProgress:Function):AssetManager
		{
			var hasFZipLibrary:Boolean = ApplicationDomain.currentDomain.hasDefinition("deng.fzip.FZip");
			if (hasFZipLibrary == false) throw new Error("FZip library required for archive import: https://github.com/claus/fzip");
			if (bytes == null) throw new ArgumentError("Parameter bytes must be non-null");

			var manager:AssetManagerZip = new AssetManagerZip();
			manager.verbose = false;
			manager.enqueueZip(bytes);
			manager.loadQueue(onProgressInner);

			function onProgressInner(ratio:Number):void
			{
				if (ratio == 1)
					importAssetManager(manager);

				if (onProgress.length == 1)
					onProgress(ratio);
				else if (ratio == 1)
					onProgress();
			}
			
			return manager;
		}
	}
}

import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.IOErrorEvent;
import flash.system.ApplicationDomain;
import flash.system.ImageDecodingPolicy;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import starling.events.Event;
import starling.utils.AssetManager;
import starling.utils.SystemUtil;

class AssetManagerZip extends AssetManager
{
	private static const PNG:String = "\u0089PNG\r\n\u001A\n";
	private static const JPG:String = "\u00FF\u00D8\u00FF";
	private static const GIF87a:String = "\u0047\u0049\u0046\u0038\u0037\u0061";
	private static const GIF89a:String = "\u0047\u0049\u0046\u0038\u0039\u0061";

	public function enqueueZip(bytes:ByteArray):void
	{
		var FZip:Class = ApplicationDomain.currentDomain.getDefinition("deng.fzip.FZip") as Class;
		
		var zip:* = new FZip();
		zip.loadBytes(bytes);

		var numFiles:int = zip.getFileCount();
		for (var i:int = 0; i < numFiles; i++)
		{
			var file:* = zip.getFileAt(i);

			var name:String = getBasenameFromUrl(file.filename);
			var asset:ByteArray = file.content;

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
			if (signature.charCodeAt(i) != source[i]) return false;

		return true;
	}
}