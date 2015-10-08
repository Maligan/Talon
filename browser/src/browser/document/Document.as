package browser.document
{
	import browser.document.files.DocumentFileReferenceCollection;
	import browser.document.files.types.AtlasAsset;
	import browser.document.files.types.DirectoryAsset;
	import browser.document.files.types.FontAsset;
	import browser.document.files.types.LibraryAsset;
	import browser.document.files.types.PropertiesAsset;
	import browser.document.files.types.StyleSheetAsset;
	import browser.document.files.types.TemplateAsset;
	import browser.document.files.types.TextureAsset;
	import browser.document.log.DocumentMessageCollection;
	import browser.document.log.DocumentTaskTracker;
	import browser.utils.Storage;
	import browser.utils.TalonFeatherTextInput;

	import flash.filesystem.File;

	import starling.events.EventDispatcher;

	[Event(name="change", type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _project:File;
		/** This is parsed _project file content. */
		private var _properties:Storage;

		private var _files:DocumentFileReferenceCollection;
		private var _factory:DocumentTalonFactory;
		private var _messages:DocumentMessageCollection;
		private var _tracker:DocumentTaskTracker;
		private var _trackerIgnore:Boolean;

		public function Document(file:File)
		{
			_properties = Storage.fromPropertiesFile(file);
			_project = file;

			_tracker = new DocumentTaskTracker(onTasksEnd);
			_messages = new DocumentMessageCollection();
			_factory = new DocumentTalonFactory(this);

			_factory.addTerminal("input");
			_factory.setLinkage("input", TalonFeatherTextInput);

			_files = new DocumentFileReferenceCollection(this);

			_files.registerController(DirectoryAsset,   DirectoryAsset.checker);
			_files.registerController(TextureAsset,     TextureAsset.checker);
			_files.registerController(TemplateAsset,    TemplateAsset.checker);
			_files.registerController(AtlasAsset,       AtlasAsset.checker);
			_files.registerController(StyleSheetAsset,  StyleSheetAsset.checker);
			_files.registerController(FontAsset,        FontAsset.checker);
			_files.registerController(LibraryAsset,     LibraryAsset.checker);
			_files.registerController(PropertiesAsset,  PropertiesAsset.checker);
		}

		/** Background task counter. */
		public function get tasks():DocumentTaskTracker { return _tracker; }
		/** Document's files. */
		public function get files():DocumentFileReferenceCollection { return _files; }
		/** Talon factory. */
		public function get factory():DocumentTalonFactory { return _factory; }
		/** Status messages (aka Errors/Warnings/Infos). */
		public function get messages():DocumentMessageCollection { return _messages; }
		/** Document properties */
		public function get properties():Storage { return _properties; }
		/** Document files *.talon */
		public function get project():File { return _project; }

		public function dispose():void
		{
			files.dispose();
		}

		//
		// Update
		//
		private function onTasksEnd():void
		{
			if (_trackerIgnore === false)
			{
				_trackerIgnore = true;

				// For same assets
				dispatchEventWith(DocumentEvent.CHANGING);

				// After CHANGING, some file controllers may start new tasks
				if (!tasks.isBusy) dispatchEventWith(DocumentEvent.CHANGED);

				_trackerIgnore = false;
			}
		}
	}
}