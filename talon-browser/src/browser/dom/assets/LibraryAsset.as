package browser.dom.assets
{
	import browser.dom.log.DocumentMessage;

	import flash.system.System;

	import talon.utils.TalonFactoryBase;

	public class LibraryAsset extends Asset
	{
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
								report(DocumentMessage.TALON_LIBRARY_WRONG_CSS, file.url);
							}

							break;

						case TalonFactoryBase.TAG_TEMPLATE:
							var templateId:String = child.@id;
							document.factory.addTemplate(child);
							_lastTemplates.push(templateId);
							break;

						default:
							report(DocumentMessage.TALON_LIBRARY_UNKNOWN_ELEMENT, file.url, childType);
					}
				}

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

			while (_lastStyleSheets.length)
				document.factory.removeStyleSheetWithId(_lastStyleSheets.pop());

			while (_lastTemplates.length)
				document.factory.removeTemplate(_lastTemplates.pop());
		}
	}
}