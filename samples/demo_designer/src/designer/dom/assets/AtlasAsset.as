package designer.dom.assets
{
	public class AtlasAsset
	{
		public function AtlasAsset()
		{
		}

		public override function initialize(document:Document, file:DocumentFileReference):void
		{
			super.initialize(document, file);
			document.addEventListener(Event.CHANGE, onDocumentChange);
		}
	}
}
