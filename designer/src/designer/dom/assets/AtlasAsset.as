package designer.dom.assets
{
	import designer.dom.Document;
	import designer.dom.files.DocumentFileReference;

	public class AtlasAsset extends Asset
	{
		public function AtlasAsset()
		{
		}

		public override function initialize(document:Document, file:DocumentFileReference):void
		{
			super.initialize(document, file);
//			document.addEventListener(Event.CHANGE, onDocumentChange);
		}
	}
}
