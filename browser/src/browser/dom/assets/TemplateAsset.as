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
				try
				{
					document.factory.addTemplate(xml);
					_lastId = xml.@id;
				}
				catch (e:ArgumentError)
				{
					report(DocumentMessage.TEMPLATE_ERROR, file.url, e.message);
				}
			}
			else
			{
				report(DocumentMessage.FILE_CONTAINS_WRONG_XML, file.url);
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