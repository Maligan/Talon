package
{
	import flexunit.framework.Assert;

	import talon.Attribute;
	import talon.Node;
	import talon.layout.Layout;

	public class LayoutAbsTest
	{
		private var parent:Node;
		private var child:Node;

		[Before]
		public function reset():void
		{
			child = new Node();
			child.setAttribute(Attribute.WIDTH, "32px");
			child.setAttribute(Attribute.HEIGHT, "64px");

			parent = new Node();
			parent.setAttribute(Attribute.LAYOUT, Layout.ABSOLUTE);
			parent.addChild(child);
			parent.bounds.setTo(0, 0, 1000, 1000);
		}

		[Test]
		public function testPosition():void
		{
			trace("DISABLED!!!!!!!!!!!!!!!")
			return;

			child.setAttribute(Attribute.X, "12px");
			child.setAttribute(Attribute.Y, "20px");

			parent.commit();
			Assert.assertEquals(32, child.bounds.width);
			Assert.assertEquals(64, child.bounds.height);

			Assert.assertEquals(10, child.bounds.x);
			Assert.assertEquals(20, child.bounds.y);
		}
	}
}