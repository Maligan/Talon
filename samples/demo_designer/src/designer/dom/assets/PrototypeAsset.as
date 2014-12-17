package designer.dom.assets
{
	public class PrototypeAsset extends Asset
	{
		protected override function onRefresh():void
		{
			document.tasks.begin();

			var xml:XML = new XML(file.read());
			var type:String = xml.@type;
			var config:XML = xml.*[0];
			document.factory.addPrototype(type, config);

			document.tasks.end();
		}
	}
}