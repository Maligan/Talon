package browser.dom
{
	import browser.dom.assets.AtlasAsset;
	import browser.dom.assets.DirectoryAsset;
	import browser.dom.assets.FontAsset;
	import browser.dom.assets.LibraryAsset;
	import browser.dom.assets.TemplateAsset;
	import browser.dom.assets.StyleSheetAsset;
	import browser.dom.assets.TextureAsset;
	import browser.dom.files.DocumentFileReference;
	import browser.dom.files.DocumentFileReferenceCollection;
	import browser.dom.files.DocumentFileType;
	import browser.dom.log.DocumentMessageCollection;
	import browser.dom.log.DocumentTaskTracker;
	import browser.AppConstants;

	import flash.filesystem.File;

	import flash.filesystem.File;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _project:File;
		/** This is parsed _project file content. */
		private var _properties:Object;

		private var _files:DocumentFileReferenceCollection;
		private var _factory:DocumentTalonFactory;
		private var _messages:DocumentMessageCollection;
		private var _tracker:DocumentTaskTracker;

		public function Document(properties:Object, file:File):void
		{
			_properties = properties;
			_project = file;

			_tracker = new DocumentTaskTracker(onTasksEnd);
			_messages = new DocumentMessageCollection();
			_factory = new DocumentTalonFactory(this);

			_files = new DocumentFileReferenceCollection(this);
			_files.registerControllerForType(DocumentFileType.DIRECTORY, DirectoryAsset);
			_files.registerControllerForType(DocumentFileType.IMAGE, TextureAsset);
			_files.registerControllerForType(DocumentFileType.TEMPLATE, TemplateAsset);
			_files.registerControllerForType(DocumentFileType.ATLAS, AtlasAsset);
			_files.registerControllerForType(DocumentFileType.STYLE, StyleSheetAsset);
			_files.registerControllerForType(DocumentFileType.BITMAP_FONT, FontAsset);
			_files.registerControllerForType(DocumentFileType.LIBRARY, LibraryAsset);
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

		public function get factory():DocumentTalonFactory
		{
			return _factory;
		}

		public function get messages():DocumentMessageCollection
		{
			return _messages;
		}

		public function get properties():Object
		{
			return _properties;
		}

		public function get project():File
		{
			return _project;
		}

		//
		// Update
		//
		private function onTasksEnd():void
		{
			dispatchEventWith(DocumentEvent.CHANGING);

			// After CHANGING, some file controllers may start new tasks
			if (!tasks.isBusy) dispatchEventWith(DocumentEvent.CHANGED);
		}
	}
}