package talon.browser.plugins.filetypes.assets
{
	import flash.system.System;

	import talon.browser.document.log.DocumentMessage;

	public class XMLTemplateAsset extends Asset
	{
		private var _id:String;
		private var _xml:XML;

		override protected function activate():void
		{
			_xml = readFileXMLOrReport();
			if (_xml == null) return;

			try
			{
				document.factory.addTemplate(_xml);
				_id = _xml.@id;
			}
			catch (e:ArgumentError)
			{
				reportMessage(DocumentMessage.TEMPLATE_ERROR, file.url, e.message);
			}
		}

		override protected function deactivate():void
		{
			document.factory.removeTemplate(_id);
			_id = null;

			_xml && System.disposeXML(_xml);
			_xml = null;
		}
	}
}