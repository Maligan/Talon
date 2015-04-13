package browser.dom.assets
{
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	import talon.utils.TalonFactoryBase;

	public class LibraryAsset extends Asset
	{
		private var _lastXML:XML;
		private var _lastStyleSheets:Vector.<String> = new Vector.<String>();
		private var _lastTemplates:Vector.<String> = new Vector.<String>();

		protected override function onRefresh():void
		{
			document.tasks.begin();

			// Clean previous data
			clean();

			// Add new data
			var xml:XML = file.readXML();
			if (xml != null)
			{
				for each (var child:XML in xml.children())
				{
					var childType:String = child.name();

					switch (childType)
					{
						case TalonFactoryBase.TAG_STYLE:
							var style:String = child.text();
							var styleId:String = file.url + "#" + _lastStyleSheets.length;

							if (StyleSheetAsset.isCSS(style))
							{
								document.factory.addStyleSheetWithId(styleId, style);
								_lastStyleSheets.push(styleId);
							}
							else
							{
								report(DocumentMessage.FILE_CONTAINS_WRONG_CSS, file.url);
							}

							break;

						case TalonFactoryBase.TAG_TEMPLATE:
							addTemplate(child);
							break;

						default:
							report(DocumentMessage.FILE_CONTAINS_WRONG_ELEMENT, file.url, childType);
					}
				}

				_lastXML = xml;
			}
			else
			{
				report(DocumentMessage.FILE_CONTAINS_WRONG_XML, file.url);
			}

			document.tasks.end();
		}

		private function addTemplate(xml:XML):void
		{
			try
			{
				var templateId:String = xml.@id;
				document.factory.addTemplate(xml);
				_lastTemplates.push(templateId);
			}
			catch (e:ArgumentError)
			{
				report(DocumentMessage.TEMPLATE_ERROR, file.url, e.message);
			}
		}

		protected override function onExclude():void
		{
			document.tasks.begin();
			clean();
			document.tasks.end();
		}

		private function clean():void
		{
			reportCleanup();

			System.disposeXML(_lastXML);
			_lastXML = null;

			while (_lastStyleSheets.length)
				document.factory.removeStyleSheetWithId(_lastStyleSheets.pop());

			while (_lastTemplates.length)
				document.factory.removeTemplate(_lastTemplates.pop());
		}
	}
}