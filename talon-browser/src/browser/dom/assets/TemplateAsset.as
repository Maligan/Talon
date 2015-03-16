package browser.dom.assets
{
	import flash.system.System;

	public class TemplateAsset extends Asset
	{
		private var _lastId:String;
		private var _lastXML:XML;

		protected override function onRefresh():void
		{
			document.tasks.begin();

			var xml:XML = new XML(file.read());
			var id:String = xml.@id;

			document.factory.removeTemplate(_lastId);
			document.factory.addTemplate(xml);

			System.disposeXML(_lastXML);
			_lastId = id;
			_lastXML = xml;

			document.tasks.end();
		}

		protected override function onExclude():void
		{
			document.factory.removeTemplate(_lastId);
			System.disposeXML(_lastXML);
			_lastId = null;
			_lastXML = null;
		}
	}
}