package talon.browser.plugins.tools.types
{
	import talon.utils.StringUtil;

	public class PropertiesAsset extends Asset
	{
		private var _properties:Object;

		public override function attach():void
		{
			var string:String = readFileStringOrReport();
			if (string == null) return;

			_properties = StringUtil.parseProperties(string);

			for (var propertyName:String in _properties)
				document.factory.addResource(propertyName, _properties[propertyName]);
		}

		public override function detach():void
		{
			reportCleanup();

            if (_properties)
                for (var propertyName:String in _properties)
                    document.factory.removeResource(propertyName);

            _properties = null;
		}
	}
}