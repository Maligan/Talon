package browser.dom.assets
{
	public class PrototypeAsset extends Asset
	{
		private var _lastId:String;

		protected override function onRefresh():void
		{
			document.tasks.begin();

			var xml:XML = new XML(file.read());
			var id:String = xml.@id;

			if (_lastId != id)
			{
				document.factory.removePrototype(_lastId);
				_lastId = id;
			}

			document.factory.addTemplate(xml);
			document.tasks.end();
		}

		protected override function onExclude():void
		{
			document.factory.removePrototype(_lastId);
		}
	}
}