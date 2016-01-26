package
{
	import flexunit.framework.Assert;

	import talon.utils.StringParseUtil;

	public class StringUtilTest
	{
		[Test]
		public function testParseFunction():void
		{
			var split:Array = null;

			split = StringParseUtil.parseFunction(null);
			Assert.assertNull(split);

			split = StringParseUtil.parseFunction("not valid functional string");
			Assert.assertNull(split);

			split = StringParseUtil.parseFunction("key()");
			Assert.assertNotNull(split);
			Assert.assertEquals(1, split.length);
		}
	}
}
