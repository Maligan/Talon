package talon.browser.platform.document.files
{
	import talon.browser.platform.document.Document;

	public class DummyFileController implements IFileController
	{
		public function attach(document:Document, reference:IFileReference):void { }
		public function detach():void { }
	}
}
