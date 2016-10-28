package
{
	import flexunit.framework.Assert;

	import talon.utils.OrderedObject;

	import talon.utils.StringParseUtil;

	public class UtilTest
	{
		[Test]
		public function testParseFunction():void
		{
			Assert.assertNull(StringParseUtil.parseFunction(null));
			Assert.assertNull(StringParseUtil.parseFunction("identifier"));
			Assert.assertEquals(1, StringParseUtil.parseFunction("key()").length);
			Assert.assertEquals(2, StringParseUtil.parseFunction("key(arg1)").length);
			Assert.assertEquals(3, StringParseUtil.parseFunction("key(arg1, arg2)").length);
		}

		[Test]
		public function testOrderedObject():void
		{
			var properties:Array =
			[
				"one",
				"two",
				"three",
				"four",
				"five",
				"six",
				"seven",
				"eight",
				"nine",
				"ten"
			];

			var object:Object = new OrderedObject();

			for (var i:int = 0; i < properties.length; i++)
			{
				var key:String = properties[i];
				var value:int = i;
				object[key] = value;
			}

			var index:int = 0;
			for (var attribute:String in object)
			{
				Assert.assertEquals(properties[index], attribute);
				Assert.assertEquals(object[attribute], index);
				index++;
			}
		}
	}
}