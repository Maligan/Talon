package talon.browser.platform.document.files
{
	import talon.browser.platform.document.Document;

	public interface IFileController
	{
		function attach(document:Document, reference:IFileReference):void;
		function detach():void;
	}
}