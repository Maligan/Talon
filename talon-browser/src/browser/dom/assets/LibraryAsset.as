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
		private var _lastMessages:Vector.<DocumentMessage> = new Vector.<DocumentMessage>();

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
							var styleId:String = file.url + "#" + _lastStyleSheets.length;
							var style:String = child.text();
							document.factory.addStyleSheetWithId(styleId, style);
							_lastStyleSheets.push(styleId);
							break;

						case TalonFactoryBase.TAG_TEMPLATE:
							var templateId:String = child.@id;
							document.factory.addTemplate(child);
							_lastTemplates.push(templateId);
							break;

						default:
							var message:DocumentMessage = new DocumentMessage(DocumentMessage.TALON_LIBRARY_UNKNOWN_ELEMENT, file.url, childType);
							document.messages.addMessage(message);
					}
				}
			}

			document.tasks.end();
		}

		protected override function onExclude():void
		{
			clean();
		}

		private function clean():void
		{
			System.disposeXML(_lastXML);

			while (_lastStyleSheets.length)
				document.factory.removeStyleSheetWithId(_lastStyleSheets.pop());

			while (_lastTemplates.length)
				document.factory.removeTemplate(_lastTemplates.pop());

			while (_lastMessages.length)
				document.messages.removeMessage(_lastMessages.pop());
		}
	}
}