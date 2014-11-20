package designer.dom
{
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.extensions.talon.utils.TalonFactory;

	public class Document extends EventDispatcher
	{
		private var _files:Vector.<DocumentFile>;
		private var _factory:TalonFactory;

		public function Document():void
		{
			_files = new Vector.<DocumentFile>();
		}

		private function onFileChange(e:Event):void
		{
			var file:DocumentFile = DocumentFile(e.target);
			dispatchEventWith(Event.CHANGE);
		}

		public function addFile(documentFile:DocumentFile):void
		{
			for each (var file:DocumentFile in _files)
				if (file.equals(documentFile))
					return;

			_files[_files.length] = documentFile;
			documentFile.addEventListener(Event.CHANGE, onFileChange);
		}

		public function get factory():TalonFactory
		{
			return _factory;
		}

		public function get files():Vector.<DocumentFile>
		{
			return _files.slice();
		}
	}
}