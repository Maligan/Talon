package talon.browser.desktop.commands
{
	import deng.fzip.FZip;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	import mx.core.FontAsset;

	import starling.events.Event;
	import starling.textures.TextureAtlas;

	import talon.browser.desktop.filetypes.CSSAsset;
	import talon.browser.desktop.filetypes.DirectoryAsset;
	import talon.browser.desktop.filetypes.PropertiesAsset;
	import talon.browser.desktop.filetypes.TextureAsset;
	import talon.browser.desktop.filetypes.XMLAtlasAsset;
	import talon.browser.desktop.filetypes.XMLLibraryAsset;
	import talon.browser.desktop.filetypes.XMLTemplateAsset;
	import talon.browser.desktop.plugins.PluginDesktopUI;
	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.DesktopFileReference;
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

		public function PublishCommand(platform:AppPlatform, target:File = null)
		{
			super(platform);
			platform.settings.addPropertyListener(AppConstants.SETTING_TEXTURE_PACKER_BIN, onTexturePackerBinChange); onTexturePackerBinChange();
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);

			_target = target;
			_ui = platform.plugins.getPlugin(PluginDesktopUI) as PluginDesktopUI;
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
			refreshPacker();
		}
		
		private function onTexturePackerBinChange():void
		{
			var packerPath:String = platform.settings.getValueOrDefault(AppConstants.SETTING_TEXTURE_PACKER_BIN);
			if (packerPath == null) _packer = null;
			else _packer = new TexturePacker(new File(packerPath));
			refreshPacker();
		}
		
		private function refreshPacker():void
		{
			if (_packer && platform.document)
			{
				_packer.init(
					getTemp(),
					"sprites_{n}.xml",
					platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_TP_ARGS, String, "--multipack --format sparrow --trim-mode None")
				)	
			}
		}

		public override function execute():void
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
			var list:Vector.<File> = new <File>[];

			// Templates, CSS, Properties
			files[AppConstants.BROWSER_DEFAULT_CACHE_FILENAME] = getCacheBytes();

			// Fonts (configs), Atlases (configs & images), Images (which does not processed by packer)
			for each (var file:IFileReference in platform.document.files.toArray())
			{
				var addToOutput:Boolean = !isIgnored(file) && !isCached(file) && !isPacked(file);
				if (addToOutput) files[getExportPath(file)] = file.data;
				if (isPacked(file)) list.push(DesktopFileReference(file).target);
			}

			// TexturePacker output
			_ui.locked = _ui.spinner = true;

			if (_packer == null) complete();
			else _packer.exec(list)
				.then(onPackerSuccess, onPackerError)
				.then(complete);

			function onPackerSuccess(result:Vector.<File>):void
			{
				for each (var file:File in result)
					files["sprites/" + file.name] = readBytes(file);
			}

			function onPackerError(e:Error):void
			{
				files = null;
				trace(e);
			}

			function complete():void
			{
				_ui.locked = _ui.spinner = false;
				if (files) writeZip(target, files);
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

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}

		//
		// Export documents properties
		//
		private function getDocumentExportPath(document:Document):String
		{
			var sourcePath:File = getSourcePath(document);
			if (sourcePath)
			{
				var exportPath:String = document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_PATH, String);
				if (exportPath)
					return sourcePath.resolvePath(exportPath).nativePath;
				else
					return sourcePath.parent.resolvePath(sourcePath.name + "." + AppConstants.BROWSER_PUBLISH_EXTENSION).nativePath;
			}

			return document.properties.getValueOrDefault(DesktopDocumentProperty.PROJECT_NAME, String)
				+ "."
				+ AppConstants.BROWSER_PUBLISH_EXTENSION;
		}

		private function getSourcePath(document:Document):File
		{
			if (document == null) return null;

			var fileReferences:Vector.<IFileReference> = document.files.toArray();
			var fileReference:DesktopFileReference = fileReferences.shift() as DesktopFileReference;

			return fileReference ? fileReference.root : null;
		}
		
		private function getCacheBytes():ByteArray
		{
			var cache:Object = getCache();
			var cacheJSON:String = JSON.stringify(cache);
			var cacheBytes:ByteArray = new ByteArray();
			cacheBytes.writeUTFBytes(cacheJSON);
			
			return cacheBytes;
		}
		
		private function getCache():Object
		{
			var files:Vector.<IFileReference> = platform.document.files.toArray();
			var stash:Vector.<IFileReference> = new <IFileReference>[];

			for each (var file:IFileReference in files)
				if (isIgnored(file) && isCached(file))
					platform.document.files.removeReference(stash[stash.length] = file);

			var cache:Object = platform.document.factory.buildCache();

			while (stash.length > 0)
				platform.document.files.addReference(stash.pop());

			return cache;
		}

		/** File is ignored for export. */
		public function isIgnored(file:IFileReference):Boolean
		{
			var fileController:IFileController = platform.document.files.getController(file.path);
			if (fileController is DirectoryAsset) return true;
			if (fileController is DummyFileController) return true;
			
			var patternsString:String = platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_PATTERN, String);
			if (patternsString == null) return false;
			
			return !Glob.matchPattern(file.path, patternsString);
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
					&& Glob.matchPattern(file.path, platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_TP_PATTERN, String, ""));
		}
		
		
		
		public function getExportPath(file:IFileReference):String
		{
			var ref:DesktopFileReference = file as DesktopFileReference;
			if (ref == null) throw new Error(); // FIXME
			
			var controller:IFileController = platform.document.files.getController(ref.path);
			if (controller is TextureAsset) return "sprites/" + ref.name;
			if (controller is TextureAtlas) return "sprites/" + ref.name;
			if (controller is FontAsset) return "fonts/" + ref.name;
			
			if (controller is XMLAtlasAsset) return ref.name;
			
			return file.path;
		}
		
		
		// TODO
		
		public function getImages():Vector.<File>
		{
			var result:Vector.<File> = new <File>[];
			
			for each (var reference:IFileReference in platform.document.files.toArray())
			{
				var desktop:DesktopFileReference = reference as DesktopFileReference;
				var controller:IFileController = platform.document.files.getController(reference.path);
				if (controller is TextureAsset && isPacked(reference)) result.push(desktop.target);
			}
			
			return result;
		}
		
		public function getTemp():File
		{
			var packerTempPath:String = platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_TP_TEMP);
			if (packerTempPath == null)
			{
				packerTempPath = File.createTempDirectory().nativePath;
				platform.document.properties.setValue(DesktopDocumentProperty.EXPORT_TP_TEMP, packerTempPath);
			}
			
			return new File(packerTempPath);
		}

		private function readBytes(file:File):ByteArray
		{
			var result:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();

			try
			{
				stream.open(file, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			finally
			{
				stream.close();
				return result;
			}
		}
	}
}