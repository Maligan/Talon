package
{
	import org.flexunit.Assert;

	import talon.Attribute;

	import talon.Node;
	import talon.utils.StyleSheet;

	public class StyleSheetTest
	{
		private var node:Node;
		private var sheet:StyleSheet;

		[Before]
		public function reset():void
		{
			node = new Node();
			sheet = new StyleSheet();
		}

		[Test]
		public function testAttributeOrder():void
		{
			sheet.parse("* { a1: 0; a2: 0; a3: 0; a4: 0; a5: 0 }");

			var styles:Object = sheet.getStyle(node);
			var array:Array = [];
			for (var name:String in styles)
				array.push(name);

			for (var i:int = 0; i < array.length; i++)
			{
				var key:String = "a" + (i + 1);
				Assert.assertEquals(key, array[i]);
			}
		}
	}
}