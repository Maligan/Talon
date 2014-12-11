package designer.dom.assets
{
	import designer.dom.Document;
	import designer.dom.files.DocumentFileReference;
	import designer.dom.files.DocumentFileType;

	import flash.utils.ByteArray;

	import starling.events.Event;

	public class PrototypeAsset extends DocumentAsset
	{
		private var _file:DocumentFileReference;

		public function PrototypeAsset(document:Document, file:DocumentFileReference)
		{
			super(document);
			if (file.type != DocumentFileType.PROTOTYPE) throw new ArgumentError("File type must be " + DocumentFileType.PROTOTYPE);

			_file = file;
			_file.addEventListener(Event.CHANGE, onFileChange);
		}

		private function onFileChange(e:Event):void
		{
			_file.removed ? exclude() : refresh();
		}

		protected override function refresh():void
		{
			var data:ByteArray = _file.read();
			var xml:XML = new XML(data);
			var type:String = xml.@type;
			var config:XML = xml.*[0];
			document.factory.addPrototype(type, config);
		}
	}
}
