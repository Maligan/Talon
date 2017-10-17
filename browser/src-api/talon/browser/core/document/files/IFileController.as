package talon.browser.core.document.files
{
	import talon.browser.core.document.Document;

	public interface IFileController
	{
		function attach(document:Document, reference:IFileReference):void;
		function detach():void;
	}
}