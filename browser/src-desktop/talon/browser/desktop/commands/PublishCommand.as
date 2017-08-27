package talon.browser.desktop.commands
{
	import deng.fzip.FZip;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	import starling.events.Event;

	import talon.browser.desktop.filetypes.CSSAsset;
	import talon.browser.desktop.filetypes.DirectoryAsset;
	import talon.browser.desktop.filetypes.PropertiesAsset;
	import talon.browser.desktop.filetypes.TextureAsset;
	import talon.browser.desktop.filetypes.XMLAtlasAsset;
	import talon.browser.desktop.filetypes.XMLFontAsset;
	import talon.browser.desktop.filetypes.XMLLibraryAsset;
	import talon.browser.desktop.filetypes.XMLTemplateAsset;
	import talon.browser.desktop.plugins.PluginDesktopUI;
	import talon.browser.desktop.popups.PromisePopup;
	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.desktop.utils.FileUtil;
	import talon.browser.desktop.utils.Promise;
	import talon.browser.desktop.utils.TexturePacker;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.document.Document;
	import talon.browser.platform.document.files.DummyFileController;
	import talon.browser.platform.document.files.IFileController;
	import talon.browser.platform.document.files.IFileReference;
	import talon.browser.platform.utils.Command;
	import talon.browser.platform.utils.Glob;

	public class PublishCommand extends Command
	{
		private var _target:File;
		private var _ui:PluginDesktopUI;
		
		private var _packer:TexturePacker;
		private var _packerPromise:Promise;
		
		public function PublishCommand(platform:AppPlatform, target:File = null)
		{
			super(platform);
			platform.settings.addPropertyListener(AppConstants.SETTING_TEXTURE_PACKER_BIN, onTexturePackerBinChange); onTexturePackerBinChange();
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);

			_target = target;
			_ui = platform.plugins.getPlugin(PluginDesktopUI) as PluginDesktopUI;
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}

		public override function get isExecuting():Boolean { return _packerPromise != null; }

		private function onDocumentChange(e:Event):void
		{
			dispatchEventChange();
			refreshPacker();
		}
		
		private function onTexturePackerBinChange():void
		{
			var packerPath:String = platform.settings.getValue(AppConstants.SETTING_TEXTURE_PACKER_BIN);
			if (packerPath == null) _packer = null;
			else _packer = new TexturePacker(new File(packerPath));
			refreshPacker();
		}
		
		private function refreshPacker():void
		{
			if (_packer && platform.document)
			{
				_packer.init(
					getPackerTempDir(),
					"sprites_{n}.xml",
					platform.document.properties.getValue(DesktopDocumentProperty.EXPORT_TP_ARGS, String, "--multipack --format sparrow --trim-mode None")
				)	
			}
		}

		override public function execute():void
		{
			if (_target != null)
			{
				publish(_target);
			}
			else
			{
				var targetPath:String = getDocumentExportPath(platform.document);
				var target:File = new File(targetPath);
				target.addEventListener(Event.SELECT, onExportFileSelect);
				target.browseForSave(AppConstants.T_EXPORT_TITLE);
			}
		}

		private function onExportFileSelect(e:*):void
		{
			var file:File = File(e.target);
			publish(file);
		}

		private function publish(target:File):void
		{
			var files:Object = {};
			var filesForPack:Vector.<File> = new <File>[];

			// Templates, CSS, Properties
			files[AppConstants.PUBLISH_CACHE_FILENAME] = getCacheBytes();

			// Fonts (configs), Atlases (configs & images), Images (which does not processed by packer)
			for each (var file:IFileReference in platform.document.files.toArray())
			{
				if (!isIgnored(file) && !isCached(file) && !isPacked(file))
					files[getExportPath(file)] = file.data;
				
				if (!isIgnored(file) && isPacked(file))
					filesForPack.push(DesktopFileReference(file).target);
			}

			if (_packer == null) complete();
			else
			{
				var popup:PromisePopup = new PromisePopup();
				_ui.popups.open(popup);
				popup.addEventListener(Event.CANCEL, _packer.stop);
				popup.setHeader("Publish As...");
				popup.setStateProcess("Pack sprites with TexturePacker...");
				
				 begin()
					.then(onPackerSuccess, onPackerError)
					.then(complete);
			}
			
			function begin():Promise
			{
				return _packerPromise = _packer.exec(filesForPack);
			}

			function onPackerSuccess(result:Vector.<File>):void
			{
				for each (var file:File in result)
					files[AppConstants.PUBLISH_SPRITES_PREFIX + file.name] = FileUtil.readBytes(file);
			}

			function onPackerError(e:Error):void
			{
				files = null;
				trace(e); // TODO: Add Error Message
			}

			function complete():void
			{
				popup && popup.close();
				_packerPromise = null;

				if (files) writeZip(target, files);
				
				dispatchEventChange();
			}
		}
		
		private function writeZip(file:File, content:Object):void
		{
			// Create zip
			var zip:FZip = new FZip();
			for (var filePath:String in content)
				zip.addFile(filePath, content[filePath]);
			
			// Save file
			var fileStream:FileStream = new FileStream();

			try
			{
				fileStream.open(file, FileMode.WRITE);

				if (zip.getFileCount() != 0)
					zip.serialize(fileStream);
			}
			finally
			{
				fileStream.close();
			}
		}

		//
		// Export documents properties
		//
		private function getDocumentExportPath(document:Document):String
		{
			var projectPath:String = platform.document.properties.getValue(DesktopDocumentProperty.PROJECT_DIR);
			var projectPathFile:File = new File(projectPath);
			
			var exportPath:String = document.properties.getValue(DesktopDocumentProperty.EXPORT_PATH, String);
			if (exportPath) return projectPathFile.resolvePath(exportPath).nativePath;
			else return projectPathFile.parent.resolvePath(projectPathFile.name + "." + AppConstants.PUBLISH_EXTENSION).nativePath;
			
			throw new Error("PROJECT_DIR_IS_NULL");
		}

		public function getExportPath(file:IFileReference):String
		{
			var ref:DesktopFileReference = file as DesktopFileReference;

			var asset:IFileController = platform.document.files.getController(ref.path);
			if (asset is TextureAsset)  return AppConstants.PUBLISH_SPRITES_PREFIX + ref.name;
			if (asset is XMLAtlasAsset)  return AppConstants.PUBLISH_SPRITES_PREFIX + ref.name;
			if (asset is XMLFontAsset)	 return AppConstants.PUBLISH_FONTS_PREFIX + ref.name;
			return ref.name;
		}
		
		private function getCacheBytes():ByteArray
		{
			var files:Vector.<IFileReference> = platform.document.files.toArray();
			var stash:Vector.<IFileReference> = new <IFileReference>[];

			// Stash ignored files from cache
			for each (var file:IFileReference in files)
				if (isIgnored(file) && isCached(file))
					platform.document.files.removeReference(stash[stash.length] = file);

			var cache:Object = platform.document.factory.buildCache();

			// Restore stash
			while (stash.length > 0)
				platform.document.files.addReference(stash.pop());

			// To ByteArray
			var cacheJSON:String = JSON.stringify(cache);
			var cacheBytes:ByteArray = new ByteArray();
			cacheBytes.writeUTFBytes(cacheJSON);
			
			return cacheBytes;
		}

		public function getPackerTempDir():File
		{
			var packerTempPath:String = platform.document.properties.getValue(DesktopDocumentProperty.EXPORT_TP_TEMP);
			if (packerTempPath == null)
			{
				packerTempPath = File.createTempDirectory().nativePath;
				platform.document.properties.setValue(DesktopDocumentProperty.EXPORT_TP_TEMP, packerTempPath);
			}

			return new File(packerTempPath);
		}
		
		// Flags

		public function isIgnored(file:IFileReference):Boolean
		{
			var fileController:IFileController = platform.document.files.getController(file.path);
			if (fileController is DirectoryAsset) return true;
			if (fileController is DummyFileController) return true;
			
			var patternsString:String = platform.document.properties.getValue(DesktopDocumentProperty.EXPORT_PATTERN, String, "*");
			if (patternsString == null) return false;
			
			return !Glob.match(file.path, patternsString);
		}

		/** File is merged into cache. */
		public function isCached(file:IFileReference):Boolean
		{
			var controller:IFileController = platform.document.files.getController(file.path);
			
			if (controller is PropertiesAsset)	return true;
			if (controller is CSSAsset)			return true;
			if (controller is XMLLibraryAsset)	return true;
			if (controller is XMLTemplateAsset)	return true;
			
			return false;
		}
		
		/** File is merged by texture atlas */
		public function isPacked(file:IFileReference):Boolean
		{
			var controller:IFileController = platform.document.files.getController(file.path);

			return controller is TextureAsset
					&& _packer != null
					&& Glob.match(file.path, platform.document.properties.getValue(DesktopDocumentProperty.EXPORT_TP_PATTERN, String, "*"));
		}
	}
}