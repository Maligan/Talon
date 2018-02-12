package starling.extensions
{
	import flash.utils.ByteArray;

	import starling.assets.AssetManager;
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
		public function importAssetManager(assets:Object):void
		{
			var oldManager:starling.utils.AssetManager = assets as starling.utils.AssetManager;
			var newManager:starling.assets.AssetManager = assets as starling.assets.AssetManager;

			if (oldManager == null && newManager == null)
				throw new Error("Parameter asstets must be instance of starling.utils.AssetManager or starling.assets.AssetManager");
			
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
		public function importArchiveAsync(bytes:ByteArray, onComplete:Function, onProgress:Function = null, onError:Function = null):starling.assets.AssetManager
		{
			var manager = new starling.assets.AssetManager();
			
			manager.registerFactory(new FZipAssetFactory());
			manager.verbose = true;
			manager.enqueueSingle(bytes);
			manager.loadQueue(onCompleteInner, onProgress, onError);
			
			function onCompleteInner():void
			{
				importAssetManager(manager);
				onComplete();
			}
			
			return manager;
		}
	}
}


import deng.fzip.FZip;
import deng.fzip.FZipFile;

import flash.utils.ByteArray;

import starling.assets.AssetFactory;
import starling.assets.AssetFactoryHelper;
import starling.assets.AssetReference;
import starling.assets.AtfTextureFactory;
import starling.assets.BitmapTextureFactory;
import starling.assets.JsonFactory;
import starling.assets.XmlFactory;
import starling.textures.TextureOptions;

class FZipAssetFactory extends AssetFactory
{
	private var _subFactories:Array;

	public function FZipAssetFactory()
	{
		addExtensions("zip");
		addMimeTypes("application/zip", "application/zip-compressed");

		_subFactories = [
			new BitmapTextureFactory(),
			new JsonFactory(),
			new XmlFactory(),
			new AtfTextureFactory()
		];
	}

	public override function canHandle(reference:AssetReference):Boolean
	{
		var superCanHandle = super.canHandle(reference);
		if (superCanHandle) return true;

		if (reference.data is ByteArray)
			return hasSignature(reference.data as ByteArray, "PK\u0003\u0004");
		
		return false;
	}

	/** Check whenever byte array starts with signature. */
	private function hasSignature(source:ByteArray, signature:String):Boolean
	{
		if (source.bytesAvailable < signature.length) return false;

		for (var i:int = 0; i < signature.length; i++)
			if (signature.charCodeAt(i) != source[i]) return false;

		return true;
	}

	public override function create(reference:AssetReference, helper:AssetFactoryHelper, onComplete:Function, onError:Function):void
	{
		// get the FZip library here: https://github.com/claus/fzip

		var abort:Boolean = false;
		var numProcessing:int = 0;
		
		var fzip:FZip = new FZip();
		fzip.loadBytes(reference.data as ByteArray);

		numProcessing++;
		var numFiles:int = fzip.getFileCount();
		for (var i:int = 0; i < numFiles; i++)
		{
			var file:FZipFile = fzip.getFileAt(i);
			var asset:AssetReference = getAssetForFile(file, helper, reference.textureOptions);

			if (asset != null)
			{
				var subFactory:AssetFactory = getFactoryFor(asset);
				if (subFactory)
				{
					numProcessing++;
					subFactory.create(asset, helper, onSubFactoryComplete, onSubFactoryError);
				}
				else
					helper.log("No suitable factory found for " + asset.url);
			}
		}
		numProcessing--;
		finishIfReady();
		
		function onSubFactoryComplete(name:String, asset:Object):void
		{
			helper.addComplementaryAsset(name, asset);
			numProcessing--;
			finishIfReady();
		}

		function onSubFactoryError(error:String):void
		{
			if (!abort)
			{
				abort = true;
				onError(error);
			}
		}

		function finishIfReady():void
		{
			if (!abort && numProcessing == 0)
				onComplete();
		}
	}
	
	private function getAssetForFile(file:FZipFile, helper:AssetFactoryHelper, textureOptions:TextureOptions)
	{
		if (file.sizeUncompressed == 0 || file.filename.indexOf("__MACOSX") != -1)
			return null;

		var subAsset:AssetReference = new AssetReference(file.content);
		subAsset.url = file.filename;
		subAsset.name = helper.getNameFromUrl(file.filename);
		subAsset.extension = helper.getExtensionFromUrl(file.filename);
		subAsset.textureOptions = textureOptions;
		
		return subAsset;
	}

	private function getFactoryFor(asset:AssetReference):AssetFactory
	{
		for each (var factory:AssetFactory in _subFactories)
			if (factory.canHandle(asset)) return factory;

		return null;
	}
}