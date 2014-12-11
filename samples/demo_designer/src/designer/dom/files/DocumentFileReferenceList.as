package designer.dom.files
{
	import flash.utils.Dictionary;

	import starling.events.Event;

	public class DocumentFileReferenceList
	{
		private var _files:Dictionary;
		private var _types:Dictionary;

		public function DocumentFileReferenceList()
		{
			_files = new Dictionary();
			_types = new Dictionary();
		}

		public function registerDocumentFileType(type:String, attach:Function = null, refresh:Function = null, detach:Function = null):void
		{
			_types[type] = { attach: attach, refresh: refresh, detach: detach };
		}

		public function addFile(file:DocumentFileReference):void
		{
			if (_files[file.url] == null)
			{
				_files[file.url] = file;
				file.addEventListener(Event.CHANGE, onFileChange);
				var attach:Function = _types[file.type] && _types[file.type].attach;
				if (attach) attach(file);
			}
		}

		public function removeFile(file:DocumentFileReference):void
		{
			if (_files[file.url] != null)
			{
				// Reference may be different
				file = _files[file.url];
				file.removeEventListener(Event.CHANGE, onFileChange);
				delete _files[file.url];
				var detach:Function = _types[file.type] && _types[file.type].detach;
				if (detach) detach(file);
			}
		}

		private function onFileChange(e:Event):void
		{
			var file:DocumentFileReference = DocumentFileReference(e.target);
			if (file.removed)
			{
				removeFile(file);
			}
			else
			{
				var refresh:Function = _types[file.type] && _types[file.type].refresh;
				if (refresh) refresh(file);
			}
		}

		public function toArray():Vector.<DocumentFileReference>
		{
			var result:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var file:DocumentFileReference in _files) result[result.length] = file;
			return result;
		}
	}
}
