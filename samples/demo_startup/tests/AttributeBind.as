package
{
	import flexunit.framework.Assert;

	import starling.extensions.talon.core.Gauge;

	import starling.extensions.talon.core.Node;

	public class AttributeBind
	{
		private var node:Node;

		[Before]
		public function setUp():void
		{
			node = new Node();
		}

		[Test]
		public function testName():void
		{
			node.width.parse("100px");

			Assert.assertEquals("100px", node.getAttribute("width"));
		}

		[Test]
		public function testName1():void
		{
			node.setAttribute("width", "100px");

			Assert.assertEquals(100, node.width.amount);
			Assert.assertEquals(Gauge.PX, node.width.unit);
		}

		[Test]
		public function testName3():void
		{
			node.getOrCreateAttribute("width").initial = "300px";
			Assert.assertEquals(300, node.width.amount);
			Assert.assertEquals(null, node.getOrCreateAttribute("width").assigned);
		}

		[Test]
		public function testName4():void
		{
			node.getOrCreateAttribute("width").styled = "200px";
			Assert.assertEquals(200, node.width.amount);
			Assert.assertEquals(null, node.getOrCreateAttribute("width").assigned);
		}
	}
}
