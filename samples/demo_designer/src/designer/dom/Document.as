package designer.dom
{
	import designer.utils.TalonDesignerFactory;

	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.filesystem.File;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.textures.Texture;

	[Event(name="change", type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _files:Vector.<DocumentFile>;
		private var _factory:TalonDesignerFactory;
		private var _source:File;
		private var _properties:Object;

		public function Document(properties:Object):void
		{
			_properties = properties;
			_files = new Vector.<DocumentFile>();
			_factory = new TalonDesignerFactory();
		}

		private function onFileChange(e:Event):void
		{
			var file:DocumentFile = DocumentFile(e.target);
			apply(file);
		}

		private function apply(file:DocumentFile, dispatch:Boolean = true):void
		{
			if (file.type == DocumentFileType.DIRECTORY)
			{

			}
			if (file.type == DocumentFileType.PROTOTYPE)
			{
				var xml:XML = new XML(file.data);
				var type:String = xml.@type;
				var config:XML = xml.*[0];
				_factory.addPrototype(type, config);
				dispatch && dispatchEventWith(Event.CHANGE);
			}
			else if (file.type == DocumentFileType.STYLE)
			{
				var text:String = file.data.toString();
				_factory.clearStyle(); // FIXME: A lot of CSS
				_factory.addStyleSheet(text);
				dispatch && dispatchEventWith(Event.CHANGE);
			}
			else if (file.type == DocumentFileType.IMAGE)
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
				loader.loadBytes(file.data);

				function onComplete(e:*):void
				{
					var texture:Texture = Texture.fromBitmap(loader.content as Bitmap);
					var key:String = file.url.substring(file.url.lastIndexOf("/") + 1, file.url.lastIndexOf("."));
					_factory.addResource(key, texture);
					dispatchEventWith(Event.CHANGE); // Всегда диспатчить
				}
			}
			else if (file.type == DocumentFileType.FONT)
			{
				trace("Font");
			}
		}

		public function addFile(documentFile:DocumentFile, silent:Boolean = false):void
		{
			for each (var file:DocumentFile in _files)
				if (file.equals(documentFile))
					return;

			_files[_files.length] = documentFile;
			apply(documentFile, !silent);
			documentFile.addEventListener(Event.CHANGE, onFileChange);
		}

		public function get factory():TalonDesignerFactory
		{
			return _factory;
		}

		public function get files():Vector.<DocumentFile>
		{
			return _files.slice();
		}

		public function get exportFileName():String
		{
			return _properties[DesignerConstants.PROPERTY_EXPORT_PATH];
		}

		/** Get in export document file name. */
		public function getExportFileName(documentFile:DocumentFile):String
		{
			return _source.getRelativePath(documentFile.file);
		}

		public function setSourcePath(file:File):void
		{
			_source = file;
		}
	}
}