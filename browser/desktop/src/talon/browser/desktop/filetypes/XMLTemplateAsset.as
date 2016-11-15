package talon.browser.desktop.filetypes
{
	import flash.system.System;

	import talon.browser.platform.document.log.DocumentMessage;
	import talon.utils.TMLFactory;

	public class XMLTemplateAsset extends Asset
	{
		private var _id:String;
		private var _xml:XML;

		override protected function activate():void
		{
			_xml = readFileXMLOrReportAndNull();
			if (_xml == null) return;

			try
			{
				document.factory.addTemplate(_xml);
				_id = _xml.attribute(TMLFactory.ATT_REF);
			}
			catch (e:ArgumentError)
			{
				reportMessage(DocumentMessage.FILE_CONTAINS_WRONG_TEMPLATE, file.path, e.message);
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