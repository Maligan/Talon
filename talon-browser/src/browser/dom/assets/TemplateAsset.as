package browser.dom.assets
{
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	public class TemplateAsset extends Asset
	{
		private var _lastId:String;

		protected override function onRefresh():void
		{
			document.tasks.begin();

			clean();

			var xml:XML = file.readXML();
			if (xml)
			{
				document.factory.addTemplate(xml);
				_lastId = xml.@id;
				System.disposeXML(xml);
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

			document.factory.removeTemplate(_lastId);
			_lastId = null;
		}
	}
}