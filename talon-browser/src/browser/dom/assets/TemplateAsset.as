package browser.dom.assets
{
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	public class TemplateAsset extends Asset
	{
		private var _lastId:String;
		private var _lastXML:XML;

		protected override function onRefresh():void
		{
			document.tasks.begin();

			clean();

			var xml:XML = file.readXML();
			if (xml)
			{
				document.factory.addTemplate(xml);
				_lastId = xml.@id;
				_lastXML = xml;
			}
			else
			{
				report(DocumentMessage.FILE_XML_PARSE_ERROR, file.url);
			}

			document.tasks.end();
		}

		protected override function onExclude():void
		{
			clean();
		}

		private function clean():void
		{
			reportCleanup();

			System.disposeXML(_lastXML);
			_lastXML = null;

			document.factory.removeTemplate(_lastId);
			_lastId = null;
		}
	}
}