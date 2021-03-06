package talon.browser.desktop.filetypes
{
	import flash.system.System;

	import talon.browser.core.document.log.DocumentMessage;
	import talon.utils.TMLParser;
	import talon.utils.TalonFactoryBase;

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
				_id = _xml.attribute(TMLParser.KEYWORD_REF);
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