package
{
	import flexunit.framework.Assert;

	import talon.Attribute;

	import talon.types.Gauge;

	import talon.Node;

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

		[Ignore]
		[Test]
		public function testName5():void
		{
			var parent:Node = new Node();
			var parentA1:Attribute = parent.getOrCreateAttribute("a1");

			var child:Node = new Node();
			var childA2:Attribute = child.getOrCreateAttribute("a2");

			childA2.bind(parentA1, function pGetValue():String { return parentA1.value; }, function(value:String):void{ childA2.unbind(); childA2.assigned = value; });

			parent.setAttribute("a1", "parent1");
			Assert.assertEquals("parent1", childA2.value, parentA1.value);

			parent.setAttribute("a1", "parent2");
			Assert.assertEquals("parent2", childA2.value, parentA1.value);

			child.setAttribute("a2", "child1");
			Assert.assertEquals("child1", childA2.value);
			Assert.assertEquals("parent2", parentA1.value);
		}
	}
}
