package talon.browser.desktop.filetypes
{
	import talon.browser.platform.document.log.DocumentMessage;

	public class XMLMalformedAsset extends Asset
	{
		protected override function activate():void
		{
			reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_XML, file.path);
		}
	}
}
