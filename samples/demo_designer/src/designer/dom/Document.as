package designer.dom
{
	import designer.dom.assets.DirectoryAsset;
	import designer.dom.assets.FontAsset;
	import designer.dom.assets.PrototypeAsset;
	import designer.dom.assets.StyleAsset;
	import designer.dom.assets.TextureAsset;
	import designer.dom.files.DocumentFileReference;
	import designer.dom.files.DocumentFileReferenceCollection;
	import designer.dom.files.DocumentFileType;
	import designer.utils.TalonDesignerFactory;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _files:DocumentFileReferenceCollection;
		private var _factory:TalonDesignerFactory;
		private var _source:File;
		private var _properties:Object;

		private var _tracker:DocumentTaskTracker;

		public function Document(properties:Object):void
		{
			_tracker = new DocumentTaskTracker(onTasksEnd);

			_properties = properties;
			_factory = new TalonDesignerFactory();
			_files = new DocumentFileReferenceCollection(this);
			_files.registerDocumentFileType(DocumentFileType.DIRECTORY, DirectoryAsset);
			_files.registerDocumentFileType(DocumentFileType.IMAGE, TextureAsset);
			_files.registerDocumentFileType(DocumentFileType.PROTOTYPE, PrototypeAsset);
			_files.registerDocumentFileType(DocumentFileType.STYLE, StyleAsset);
			_files.registerDocumentFileType(DocumentFileType.FONT, FontAsset);
		}

		public function get isBusy():Boolean
		{
			return _tracker.isBusy;
		}

		/** Background task counter. */
		public function get tasks():DocumentTaskTracker
		{
			return _tracker;
		}

		/** Document's files. */
		public function get files():DocumentFileReferenceCollection
		{
			return _files;
		}

		public function get factory():TalonDesignerFactory
		{
			return _factory;
		}

		//
		// Update timer
		//
		private function onTasksEnd():void
		{
			dispatchEventWith(Event.CHANGE);
		}

		//
		// Export
		//
		public function get exportFileName():String
		{
			return _properties[DesignerConstants.PROPERTY_EXPORT_PATH];
		}

		/** Get in export document file name. */
		public function getExportFileName(documentFile:DocumentFileReference):String
		{
			return _source.getRelativePath(documentFile.file);
		}

		public function setSourcePath(file:File):void
		{
			_source = file;
		}
	}
}
